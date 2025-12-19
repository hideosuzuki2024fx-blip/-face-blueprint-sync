param(
  [Parameter(Mandatory=$true)]
  [string]$Query,
  [string]$RepoRoot = "",
  [string]$Token = "",
  [string]$ConfirmPush = ""
)

function Normalize-PathLike([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $winish = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($winish) } catch { $winish }
}
function Resolve-RepoRoot([string]$RepoRootParam) {
  $stateFile = "E:\ai_dev_core\.gitgpt\current_repo.txt"
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParam)) { return Normalize-PathLike $RepoRootParam }
  if (Test-Path $stateFile) {
    $p = (Get-Content $stateFile -Raw -Encoding UTF8).Trim()
    if (-not [string]::IsNullOrWhiteSpace($p)) { return Normalize-PathLike $p }
  }
  return "E:\ai_dev_core"
}

$repo = Resolve-RepoRoot $RepoRoot
Set-Location $repo

# 安全確認
$top = Normalize-PathLike (git rev-parse --show-toplevel 2>$null)
$inside = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top) { Write-Error "Git 管理下ではありません。"; exit 1 }
if (-not [String]::Equals($top, (Normalize-PathLike $repo), [System.StringComparison]::OrdinalIgnoreCase)) {
  Write-Error ("想定外のパスです: {0}" -f $top); exit 1
}

# --- 簡易 NLP: 意図推定（日本語/英語、境界なし） ---
$Q = $Query.Trim()

function Extract-Message([string]$s) {
  if ($s -match '["“](.+?)["”]') { return $Matches[1] }
  if ($s -match '(?i)(msg|message|メッセージ)\s*[:：]\s*(.+)$') { return $Matches[2].Trim() }
  return ""
}
function Extract-NameAfterAny([string]$s, [string[]]$keywords) {
  foreach ($kw in $keywords) {
    $rx = "(?i)" + [Regex]::Escape($kw) + "\s+([A-Za-z0-9._/\-]+)"
    if ($s -match $rx) { return $Matches[1] }
  }
  # 「feature/x に切り替え」など最後のトークンを拾うフォールバック
  if ($s -match '(?i)\s([A-Za-z0-9._/\-]+)\s*$') { return $Matches[1] }
  return ""
}

$msg    = Extract-Message $Q
$paths  = @()
$branch = ""
$intent = ""

# paths/files 指定
if ($Q -match '(?i)(paths|files?)\s*[:：]\s*([^\s].+)$') {
  $raw = $Matches[2].Trim()
  $paths = @($raw -split '[,\s]+' | Where-Object { $_ -ne "" })
}
if (-not $paths -or $paths.Count -eq 0) { $paths = @(".") }

# キーワード検出（順序重要）
if ($Q -match '(?i)(commit|コミット)')               { $intent = "commit" }
elseif ($Q -match '(?i)(push|プッシュ)')             { $intent = "push" }
elseif ($Q -match '(?i)(pull|プル|fetch)')           { $intent = "pull" }
elseif ($Q -match '(?i)(diff|差分|変更点|変更のみ)')  { $intent = "diff" }
elseif ($Q -match '(?i)(status|ステータス|状態)')     { $intent = "status" }
elseif ($Q -match '(?i)(branch|ブランチ).*(create|作成|new)') {
  $intent = "branch_create"
  $branch = Extract-NameAfterAny $Q @("ブランチ作成","branch create","branch")
}
elseif ($Q -match '(?i)(branch|ブランチ).*(switch|切替|checkout)') {
  $intent = "branch_switch"
  $branch = Extract-NameAfterAny $Q @("ブランチ","branch","checkout","切替")
}
elseif ($Q -match '(?i)(tag|タグ).*(create|作成|new)') {
  $intent = "tag_create"
  $branch = Extract-NameAfterAny $Q @("タグ","tag")
}
else { $intent = "status" }

# PLAN 表示
Write-Host "=== PLAN ==="
Write-Host ("repo   : {0}" -f $repo)
Write-Host ("intent : {0}" -f $intent)
if ($intent -eq "commit") {
  Write-Host ("message: {0}" -f ($(if ($msg){$msg}else{"(空)"})))
  Write-Host ("paths  : {0}" -f ($paths -join ", "))
} elseif ($intent -like "branch_*" -or $intent -eq "tag_create") {
  Write-Host ("name   : {0}" -f ($(if ($branch){$branch}else{"(未指定)"})))
}

# プレビュー（安全）
switch ($intent) {
  "status" { git status --porcelain=v1; break }
  "diff"   { git diff --stat -- $paths; break }
  default  {
    git status --porcelain=v1 -- $paths
    if ($intent -eq "commit") { git diff --stat -- $paths }
  }
}

# 承認要否
function IsReadOnlyIntent([string]$i) { return ($i -eq "status" -or $i -eq "diff") }
function NeedsDouble([string]$i)     { return ($i -eq "push") }

if (-not (IsReadOnlyIntent $intent)) {
  if ($Token -ne "承認" -or (NeedsDouble $intent -and $ConfirmPush -ne "承認")) {
    Write-Host "`n承認が不足しています。実行しません。"
    Write-Host "実行例:"
    switch ($intent) {
      "push"   { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認 -ConfirmPush 承認" }
      default  { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認" }
    }
    exit 2
  }
}

# APPLY
switch ($intent) {
  "commit" {
    if (-not $msg) { $msg = "chore: update via nl dispatcher" }
    git add -- $paths
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    git commit -m $msg
    exit $LASTEXITCODE
  }
  "pull" {
    $cur = (git rev-parse --abbrev-ref HEAD).Trim()
    git fetch origin
    git pull origin $cur
    exit $LASTEXITCODE
  }
  "push" {
    # remote URL 検査（ダミー/未設定なら中断）
    $remoteUrl = ""
    git remote get-url origin 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) { $remoteUrl = (git remote get-url origin).Trim() }
    if ([string]::IsNullOrWhiteSpace($remoteUrl) -or $remoteUrl -match "<|>") {
      Write-Error "remote 'origin' のURLが未設定/ダミーです。remote_wizard.ps1 で設定してください。"; exit 3
    }
    $head = (git rev-parse --abbrev-ref HEAD).Trim()
    $up = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    $hasU = $true
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($up)) { $hasU = $false }
    if ($hasU) { git push origin $head } else { git push -u origin $head }
    exit $LASTEXITCODE
  }
  "branch_create" {
    if (-not $branch) { Write-Error "ブランチ名が不明です。"; exit 1 }
    git switch -c $branch
    exit $LASTEXITCODE
  }
  "branch_switch" {
    if (-not $branch) { Write-Error "ブランチ名が不明です。"; exit 1 }
    git switch $branch
    exit $LASTEXITCODE
  }
  "tag_create" {
    if (-not $branch) { Write-Error "タグ名が不明です。"; exit 1 }
    git tag $branch
    exit $LASTEXITCODE
  }
  default { exit 0 }
}

# === Token 正規化 & 環境変数フォールバック ===
$Token       = if ([string]::IsNullOrWhiteSpace($Token))       { $env:AI_GIT_TOKEN }       else { $Token }
$ConfirmPush = if ([string]::IsNullOrWhiteSpace($ConfirmPush)) { $env:AI_GIT_PUSH_OK }     else { $ConfirmPush }
$Token       = if ($Token)       { $Token.Trim() }       else { "" }
$ConfirmPush = if ($ConfirmPush) { $ConfirmPush.Trim() } else { "" }

function IsReadOnlyIntent([string]$i) { return ($i -eq "status" -or $i -eq "diff") }
function NeedsDouble([string]$i)     { return ($i -eq "push") }

# ---- 承認チェック（不足項目の明示化） ----
if (-not (IsReadOnlyIntent $intent)) {
  $missing = @()
  if ($Token -ne "承認") { $missing += "Token" }
  if (NeedsDouble $intent -and $ConfirmPush -ne "承認") { $missing += "ConfirmPush" }
  if ($missing.Count -gt 0) {
    Write-Host "`n承認が不足しています: $($missing -join ', ')。実行しません。"
    Write-Host "実行例:"
    switch ($intent) {
      "push"   { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認 -ConfirmPush 承認" }
      default  { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認" }
    }
    Write-Host "`n環境変数でも指定できます:"
    Write-Host '$env:AI_GIT_TOKEN   = "承認"'
    Write-Host '$env:AI_GIT_PUSH_OK = "承認"   # push 用'
    exit 2
  }
}
