param(
  [string]\ = "origin",
  [string]\ = "",
  [string]\ = "",
  [string]\ = "",
  [string]\ = ""
)

function Normalize-PathLike([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $winish = $p -replace '/', '\'
  try { return [System.IO.Path]::GetFullPath($winish) } catch { return $winish }
}
function Resolve-RepoRoot([string]$RepoRootParam) {
  $stateFile = "E:\ai_dev_core\.gitgpt\current_repo.txt"
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParam)) {
    return Normalize-PathLike $RepoRootParam
  }
  if (Test-Path $stateFile) {
    $p = Get-Content $stateFile -Raw -Encoding UTF8
    if (-not [string]::IsNullOrWhiteSpace($p)) { return Normalize-PathLike $p.Trim() }
  }
  return "E:\ai_dev_core"
}

\ = Resolve-RepoRoot \
Set-Location \
\ = Normalize-PathLike (git rev-parse --show-toplevel)
if (-not [String]::Equals(\, (Normalize-PathLike \), [System.StringComparison]::OrdinalIgnoreCase)) { Write-Error ("想定外のパスです: {0}" -f \); exit 1 }

if ([string]::IsNullOrWhiteSpace(\)) { \ = (git rev-parse --abbrev-ref HEAD).Trim() }

\ = \True
\ = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(\)) { \ = \False; \ = "\/\ (will set)" } else { \ = \.Trim() }

# PLAN
Write-Host "=== PLAN: git push ==="
Write-Host ("repo         : {0}" -f \)
Write-Host ("remote       : {0}" -f \)
Write-Host ("branch       : {0}" -f \)
Write-Host ("upstream     : {0}" -f \)
if (\) {
  \ = (git rev-list --left-right --count "\...HEAD") -split '\s+'
  if (\.Length -ge 2) { Write-Host ("ahead/behind : +{0} / -{1}" -f \[1], \[0]) }
  Write-Host "
-- commits to push --"; git log --oneline "\..HEAD" -n 50
} else {
  Write-Host "
-- commits to push (no upstream yet) --"; git log --oneline -n 50
}

if (\ -ne "承認" -or \ -ne "承認") {
  Write-Host "
実行には二段階承認が必要です。"
  Write-Host "例: .\scripts\git_safe_push.ps1 -RepoRoot "\" -Token 承認 -ConfirmPush 承認"; exit 2
}

Write-Host "
=== APPLY: git push ==="
if (\) { git push \ \ } else { git push -u \ \ }
exit $LASTEXITCODE
