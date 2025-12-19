param(
    [Parameter(Mandatory=\True)]
    [string]\,
    [string[]]\ = @("."),
    [switch]\,
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
\ = Normalize-PathLike \
Set-Location \

# 安全確認
\ = git rev-parse --show-toplevel 2>$null
\ = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not \ -or -not \) { Write-Error "Git 管理下ではありません。"; exit 1 }
\ = Normalize-PathLike \
if (-not [String]::Equals(\, \, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Error ("想定外のパスです: {0} (expected {1})" -f \, \); exit 1
}

# PLAN
Write-Host "=== PLAN (git status) ==="
git status --porcelain=v1 -- \
Write-Host "
=== DIFF (summary) ==="
git diff --stat -- \

# 承認
if (\ -ne "承認") {
    Write-Host "
承認トークンがありません。実行を中止します。"
    Write-Host "実行する場合は -Token 承認 を付けてください。"; exit 2
}

# APPLY
Write-Host "
=== APPLY (git add) ==="
git add -- \
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "
=== APPLY (git commit) ==="
\ = @("commit","-m",\)
if (\) { \ += "--no-verify" }
git @commitArgs
exit $LASTEXITCODE
