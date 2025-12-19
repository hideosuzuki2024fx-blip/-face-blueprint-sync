param(
  [string]\ = "origin",
  [Parameter(Mandatory=$true)]
  [string]\,
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

Write-Host "=== PLAN: set remote ==="
Write-Host ("repo         : {0}" -f \)
Write-Host ("target remote: {0}" -f \)
Write-Host ("target url   : {0}" -f \)
Write-Host ("branch       : {0}" -f \)
Write-Host "
-- current remotes --"; git remote -v

if (\ -ne "承認") { Write-Host "
適用には承認が必要です。"; exit 2 }

git remote get-url \ 1>$null 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "
=== APPLY: git remote set-url ==="
  git remote set-url \ \
} else {
  Write-Host "
=== APPLY: git remote add ==="
  git remote add \ \
}

\ = \True
\ = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(\)) { \ = \False }

if (-not \ -and \ -eq "承認") {
  Write-Host "
=== APPLY: initial push with upstream (-u) ==="
  git push -u \ \
} elseif (-not \) {
  Write-Host "
upstream が未設定です。初回 push を行うには -ConfirmPush 承認 を併用してください。"
}
