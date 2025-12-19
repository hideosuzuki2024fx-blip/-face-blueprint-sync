# 承認トークンで埋め込みリポジトリを除外＆コミット（pushなし）

param(
  [string]$RepoRoot = "E:\ai_dev_core"
)

function Normalize-PathLike([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $winish = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($winish) } catch { $winish }
}

Set-Location $RepoRoot

# 安全確認
$top = Normalize-PathLike (git rev-parse --show-toplevel)
$expected = Normalize-PathLike $RepoRoot
if (-not [String]::Equals($top, $expected, [System.StringComparison]::OrdinalIgnoreCase)) {
  Write-Error ("想定外のパスです: {0} (expected {1})" -f $top, $expected); exit 1
}

# 自分自身の .git は除外
$ownGit = Normalize-PathLike (Join-Path $RepoRoot ".git")
$embeddedAbs = Get-ChildItem -Path $RepoRoot -Recurse -Directory -Filter ".git" -Force `
  | Where-Object { (Normalize-PathLike $_.FullName) -ne $ownGit } `
  | ForEach-Object { Split-Path -Path $_.FullName -Parent } `
  | Sort-Object -Unique

if (-not $embeddedAbs -or $embeddedAbs.Count -eq 0) {
  Write-Host "埋め込みリポジトリは見つかりませんでした。変更なし。"; exit 0
}

# 相対化
function To-Rel([string]$abs) {
  $uBase = New-Object System.Uri((Normalize-PathLike $RepoRoot) + '\')
  $uT    = New-Object System.Uri((Normalize-PathLike $abs))
  ($uBase.MakeRelativeUri($uT).ToString()).Replace('/','\')
}
$embeddedRel = @()
foreach ($abs in $embeddedAbs) {
  $rel = To-Rel $abs
  if ($rel -and $rel -ne "." -and $rel -ne "\") { $embeddedRel += ($rel -replace '^[\\]+','') }
}
$embeddedRel = $embeddedRel | Sort-Object -Unique

Write-Host "=== PLAN: embedded repos ==="
$embeddedRel | ForEach-Object { Write-Host " - $_" }

# .gitignore 追記内容を準備
$gitignorePath = Join-Path $RepoRoot ".gitignore"
$current = ""; if (Test-Path $gitignorePath) { $current = Get-Content $gitignorePath -Raw -Encoding UTF8 }
$toAppend = @()
foreach ($d in $embeddedRel) {
  $line = ($d.TrimEnd('\') + "/").Replace('\','/')
  if ($current -notmatch [regex]::Escape($line)) { $toAppend += $line }
}

# === 承認が必要 ===
$token = Read-Host "実行するには 承認 と入力してください"
if ($token -ne "承認") { Write-Host "承認なし。中止します。"; exit 2 }

# .gitignore 追記
$gitignoreUpdated = $false
if ($toAppend.Count -gt 0) {
  Add-Content -Path $gitignorePath -Value "`n# embedded git repos`n$($toAppend -join \"`n\")" -Encoding UTF8
  $gitignoreUpdated = $true
  Write-Host ".gitignore に追記:"; $toAppend | ForEach-Object { Write-Host " + $_" }
} else {
  Write-Host ".gitignore への追記は不要でした。"
}

# インデックスからの除外
$untrackedChanges = $false
Write-Host "`n=== APPLY: index から除外 ==="
foreach ($d in $embeddedRel) {
  $tracked = git ls-files -- "$d" "$d/*" 2>$null
  if ($tracked) {
    git rm --cached -r -- "$d"
    if ($LASTEXITCODE -ne 0) { Write-Error "rm --cached に失敗: $d"; exit $LASTEXITCODE }
    $untrackedChanges = $true
  } else {
    Write-Host " (skip) not tracked: $d"
  }
}

# コミット
if ($gitignoreUpdated -or $untrackedChanges) {
  git add -- ".gitignore"
  git commit -m "chore: ignore embedded git repos and untrack from index"
  if ($LASTEXITCODE -ne 0) { Write-Error "コミットに失敗しました"; exit $LASTEXITCODE }
  Write-Host "`n完了: 埋め込みリポジトリを除外してコミットしました。（pushなし）"
} else {
  Write-Host "`n変更はありません。コミットはスキップしました。"
}

# 確認
Write-Host "`n=== STATUS ==="; git status --porcelain=v1
Write-Host "`n=== DIFF (summary) ==="; git diff --stat
