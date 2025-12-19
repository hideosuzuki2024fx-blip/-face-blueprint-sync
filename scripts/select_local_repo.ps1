param(
  [string]$Root = "E:\",
  [int]$Depth = 3
)

function Normalize-PathLike([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $winish = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($winish) } catch { $winish }
}

$Root = Normalize-PathLike $Root
if ($Root -notlike "E:\*") { Write-Error "E:\ 配下のみ走査します。"; exit 1 }

Write-Host "=== SCAN: Git repositories under $Root (depth=$Depth) ==="
$repos = @()
try {
  $gits = Get-ChildItem -Path $Root -Recurse -Directory -Depth $Depth -Filter ".git" -Force 2>$null
  foreach ($g in $gits) {
    $repo = Normalize-PathLike (Split-Path -Parent $g.FullName)
    if ($repo -and ($repos -notcontains $repo)) { $repos += $repo }
  }
} catch {
  Write-Error "走査に失敗: $($_.Exception.Message)"; exit 1
}

if ($repos.Count -eq 0) { Write-Host "見つかりませんでした。"; exit 0 }

for ($i=0; $i -lt $repos.Count; $i++) {
  Write-Host ("[{0}] {1}" -f $i, $repos[$i])
}

$idx = Read-Host "番号を入力してください"
if ($idx -notmatch '^\d+$' -or [int]$idx -ge $repos.Count) {
  Write-Error "不正な番号です。"; exit 1
}

$selected = $repos[[int]$idx]
# 検証
Set-Location $selected
$top = Normalize-PathLike (git rev-parse --show-toplevel 2>$null)
$inside = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top) { Write-Error "Git 管理下ではありません。"; exit 1 }

# 保存
$state = "E:\ai_dev_core\.gitgpt\current_repo.txt"
$selected | Set-Content -Path $state -Encoding UTF8
Write-Host ("選択されたリポジトリ: {0}" -f $selected)
Write-Host ("保存しました: {0}" -f $state)
