param(
  [string]$Remote = "origin",
  [string]$Branch = "",
  [string]$Token = "",
  [string]$ConfirmPush = ""
)

function Normalize-PathLike([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $winish = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($winish) } catch { $winish }
}

# ルート固定 & 安全確認
$repo = "E:\ai_dev_core"
Set-Location $repo
$top = Normalize-PathLike (git rev-parse --show-toplevel)
if (-not [String]::Equals($top, (Normalize-PathLike $repo), [System.StringComparison]::OrdinalIgnoreCase)) {
  Write-Error ("想定外のパスです: {0}" -f $top); exit 1
}

# 現在ブランチ/Upstream検出
if ([string]::IsNullOrWhiteSpace($Branch)) {
  $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
}
$hasUpstream = $true
$upstream = git rev-parse --abbrev-ref @{u} 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
  $hasUpstream = $false
  $upstream = "$Remote/$Branch (will set)"
}

# ahead/behind
$ahead = 0; $behind = 0
if ($hasUpstream) {
  $counts = (git rev-list --left-right --count @{u}...HEAD) -split '\s+'
  if ($counts.Length -ge 2) { $behind = [int]$counts[0]; $ahead = [int]$counts[1] }
}

Write-Host "=== PLAN: git push ==="
Write-Host ("remote     : {0}" -f $Remote)
Write-Host ("branch     : {0}" -f $Branch)
Write-Host ("upstream   : {0}" -f $upstream)
if ($hasUpstream) {
  Write-Host ("ahead/behind: +{0} / -{1}" -f $ahead, $behind)
}
Write-Host "`n-- Commits to push --"
if ($hasUpstream) {
  git log --oneline @{u}..HEAD -n 50
} else {
  git log --oneline -n 50
}

# 二段階承認
if ($Token -ne "承認" -or $ConfirmPush -ne "承認") {
  Write-Host "`n実行には二段階承認が必要です。"
  Write-Host "例: .\scripts\git_safe_push.ps1 -Token 承認 -ConfirmPush 承認"
  exit 2
}

Write-Host "`n=== APPLY: git push ==="
if ($hasUpstream) {
  git push $Remote $Branch
} else {
  git push -u $Remote $Branch
}
exit $LASTEXITCODE
