param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [string[]]$Paths = @("."),
    [switch]$NoVerify,
    [string]$Token = ""
)

Set-Location "E:\ai_dev_core"

# 安全確認
$top = git rev-parse --show-toplevel 2>$null
$inside = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top) {
    Write-Error "Git 管理下ではありません。処理を中止します。"
    exit 1
}
if ($top -ne "E:\ai_dev_core") {
    Write-Error "想定外のパスです: $top"
    exit 1
}

# 差分要約
Write-Host "=== PLAN (git status) ==="
git status --porcelain=v1

Write-Host "`n=== DIFF (summary) ==="
git diff --stat

# 承認トークン確認
if ($Token -ne "承認") {
    Write-Host "`n承認トークンがありません。実行を中止します。"
    Write-Host "実行する場合は -Token 承認 を付けてください。"
    exit 2
}

# 実行
Write-Host "`n=== APPLY (git add) ==="
git add -- $Paths
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== APPLY (git commit) ==="
$commitArgs = @("commit","-m",$Message)
if ($NoVerify) { $commitArgs += "--no-verify" }
git @commitArgs
exit $LASTEXITCODE
