param()

function Ask($msg, $default=$null) {
  while ($true) {
    $q = if ($default) { "$msg [$default]" } else { $msg }
    $v = Read-Host $q
    if ([string]::IsNullOrWhiteSpace($v)) {
      if ($default) { return $default } else { Write-Host "必須項目です。もう一度入力してください。" -ForegroundColor Yellow }
    } else { return $v }
  }
}
function AskSecret($msg) {
  while ($true) {
    $s = Read-Host $msg -AsSecureString
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    $v = [Runtime.InteropServices.Marshal]::PtrToStringAuto($b)
    if (-not [string]::IsNullOrWhiteSpace($v)) { return $v }
    Write-Host "必須項目です。もう一度入力してください。" -ForegroundColor Yellow
  }
}
function Mask($s) {
  if (-not $s) { return "<empty>" }
  $len = $s.Length
  $head = if ($len -ge 4) { $s.Substring(0,4) } else { $s }
  return "$head*** (len=$len)"
}

# 1) 値の聞き取り（置換不要）
$endpoint = Ask "VercelのエンドポイントURL（例: https://your-app.vercel.app）"
$repo     = Ask "GitHubのコンテンツRepo（owner/repo 例: yourname/face-blueprint-content）"
$branch   = Ask "ブランチ名" "main"
$yamlPath = Ask "YAMLパス" "characters.yaml"
$bearer   = AskSecret "API_BEARER（Vercelに設定した値と同じもの）"

# 2) 環境変数（セッション）に設定
$env:API_BEARER      = $bearer
$env:REPO_SLUG       = $repo
$env:BRANCH          = $branch
$env:YAML_PATH       = $yamlPath
$env:VERCEL_ENDPOINT = $endpoint

# 3) 疎通テスト（/api/register を使用）
$call = Join-Path $PSScriptRoot "call_register.ps1"
if (-not (Test-Path $call)) {
  Write-Error "call_register.ps1 が見つかりません。先に作成してください。"; exit 1
}
try {
  Set-Location $PSScriptRoot
  .\call_register.ps1 -endpoint $endpoint | Tee-Object -Variable result | Out-Null
  Write-Host "疎通テスト結果:" -ForegroundColor Cyan
  $result | Out-String | Write-Host
} catch {
  Write-Error "疎通テストに失敗しました。$($_.Exception.Message)"
}

# 4) マスクした設定ログを保存
$log = @"
# Face Blueprint Sync – env setup (masked)
Endpoint : $endpoint
Repo     : $repo
Branch   : $branch
YamlPath : $yamlPath
API_BEARER: $(Mask($bearer))
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
"@
$logFile = Join-Path $PSScriptRoot "_env_setup_log.txt"
$log | Out-File -FilePath $logFile -Encoding utf8 -Force
