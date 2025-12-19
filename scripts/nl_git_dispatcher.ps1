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

# --- 簡易 NLP: 意図推定 ---
$Q = $Query.Trim()

# 抽出補助
function Extract-Message([string]$s) {
  # 引用符内、または 'msg:' / 'メッセージ:' の後を拾う簡易版
  if ($s -match '["“](.+?)["”]') { return $Matches[1] }
  if ($s -match '(?i)(msg|message|メッセージ)\s*[:：]\s*(.+)$') { return $Matches[2].Trim() }
  return ""
}
function Extract-NameAfter([string]$s, [string]$kw) {
  if ($s -match ("(?i)" + [regex]::Escape($kw) + "\s+([A-Za-z0-9._/\-]+)")) { return $Matches[1] }
  return ""
}

$intent = ""
$plan   = @{}
$msg    = Extract-Message $Q
$branch = ""
$paths  = @()

# パス指定（paths: xxx,yyy）/ or 明示キーワード files:
if ($Q -match '(?i)(paths|files?)\s*[:：]\s*([^\s].+)$') {
  $raw = $Matches[2].Trim()
  $paths = @($raw -split '[,\s]+' | Where-Object { $_ -ne "" })
}

# 意図判定（優先度順）
if ($Q -match '(?i)\b(status|ステータス|状態)\b') { $intent = "status" }
elseif ($Q -match '(?i)\b(diff|差分)\b') { $intent = "diff" }
elseif ($Q -match '(?i)\b(commit|コミット)\b') { $intent = "commit" }
elseif ($Q -match '(?i)\b(pull|プル|fetch)\b') { $intent = "pull" }
elseif ($Q -match '(?i)\b(push|プッシュ)\b') { $intent = "push" }
elseif ($Q -match '(?i)\b(branch|ブランチ).*(create|作成|new)') { $intent = "branch_create"; $branch = Extract-NameAfter $Q "branch|ブランチ" }
elseif ($Q -match '(?i)\b(branch|ブランチ).*(switch|切替|checkout)') { $intent = "branch_switch"; $branch = Extract-NameAfter $Q "branch|ブランチ" }
elseif ($Q -match '(?i)\b(tag|タグ).*(create|作成|new)') { $intent = "tag_create"; $branch = Extract-NameAfter $Q "tag|タグ" }
else { $intent = "status" }

# 既定パス
if (-not $paths -or $paths.Count -eq 0) { $paths = @(".") }

# --- PLAN 表示 ---
Write-Host "=== PLAN ==="
Write-Host ("repo   : {0}" -f $repo)
Write-Host ("intent : {0}" -f $intent)
if ($intent -eq "commit") {
  Write-Host ("message: {0}" -f ($(if ($msg) { $msg } else { "(空)" })))
  Write-Host ("paths  : {0}" -f ($paths -join ", "))
} elseif ($intent -like "branch_*" -or $intent -eq "tag_create") {
  Write-Host ("name   : {0}" -f ($(if ($branch){$branch}else{"(未指定)"})))
}

switch ($intent) {
  "status" { git status --porcelain=v1; break }
  "diff"   { git diff --stat -- $paths; break }
  default {
    # 軽くプレビュー
    git status --porcelain=v1 -- $paths
    if ($intent -eq "commit") { git diff --stat -- $paths }
  }
}

# --- 承認チェック ---
function Need-Approval() { return $true }
function Need-DoubleApproval() {
  # push は二段階承認
  return $intent -eq "push"
}

if ($Token -ne "承認" -or (Need-DoubleApproval) -and ($ConfirmPush -ne "承認")) {
  Write-Host "`n承認が不足しています。実行しません。"
  Write-Host "実行例:"
  switch ($intent) {
    "commit" { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認" }
    "push"   { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認 -ConfirmPush 承認" }
    default  { Write-Host ".\scripts\nl_git_dispatcher.ps1 -Query `"$($Query)`" -Token 承認" }
  }
  exit 2
}

# --- APPLY ---
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
    # upstream 有無で分岐
    $up = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    $hasU = $true
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($up)) { $hasU = $false }
    if ($hasU) { git push origin (git rev-parse --abbrev-ref HEAD).Trim() }
    else { git push -u origin (git rev-parse --abbrev-ref HEAD).Trim() }
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
