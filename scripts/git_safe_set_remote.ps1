param(
  [string]$Remote = "origin",
  [Parameter(Mandatory=$true)]
  [string]$RemoteUrl,
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

if ([string]::IsNullOrWhiteSpace($Branch)) {
  $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
}

# 現在の remote 一覧
$currentRemotes = (git remote -v) 2>$null

Write-Host "=== PLAN: set remote ==="
Write-Host ("target remote : {0}" -f $Remote)
Write-Host ("target url    : {0}" -f $RemoteUrl)
Write-Host ("branch        : {0}" -f $Branch)
Write-Host "`n-- current remotes --"
$currentRemotes

# 承認チェック
if ($Token -ne "承認") {
  Write-Host "`n適用には承認が必要です。"
  Write-Host "例: .\scripts\git_safe_set_remote.ps1 -RemoteUrl https://github.com/owner/repo.git -Token 承認"
  exit 2
}

# 適用: add or set-url
$hasRemote = $false
if ($currentRemotes -and ($currentRemotes | Select-String -SimpleMatch "^$Remote\s")) { $hasRemote = $true }

if ($hasRemote) {
  Write-Host "`n=== APPLY: git remote set-url ==="
  git remote set-url $Remote $RemoteUrl
} else {
  Write-Host "`n=== APPLY: git remote add ==="
  git remote add $Remote $RemoteUrl
}

# upstream 有無チェック
$hasUpstream = $true
$upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
  $hasUpstream = $false
  $upstream = "(none)"
} else {
  $upstream = $upstream.Trim()
}

Write-Host ("upstream     : {0}" -f $upstream)

# オプション: 初回 push（二段階承認）
if (-not $hasUpstream -and $ConfirmPush -eq "承認") {
  Write-Host "`n=== APPLY: initial push with upstream (-u) ==="
  git push -u $Remote $Branch
  exit $LASTEXITCODE
} elseif (-not $hasUpstream) {
  Write-Host "`nupstream が未設定です。初回 push を行うには -ConfirmPush 承認 を併用してください。"
  Write-Host "例: .\scripts\git_safe_set_remote.ps1 -RemoteUrl URL -Token 承認 -ConfirmPush 承認"
} else {
  Write-Host "`nupstream は既に設定されています。push は未実行です。"
}
