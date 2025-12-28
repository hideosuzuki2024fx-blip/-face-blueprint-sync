param()

function Ask($msg, $default = $null) {
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
  $len  = $s.Length
  $head = if ($len -ge 4) { $s.Substring(0,4) } else { $s }
  return "$head*** (len=$len)"
}

# 対話入力
$endpoint = Ask "VercelのエンドポイントURL（例: https://your-app.vercel.app）"
$repo     = Ask "GitHubのコンテンツRepo（owner/repo 例: yourname/face-blueprint-content）"
$branch   = Ask "ブランチ名" "main"
$yamlPath = Ask "YAMLパス" "characters.yaml"
$bearer   = AskSecret "API_BEARER（Vercelに設定した値と同じもの）"

# セッション環境変数
$env:VERCEL_ENDPOINT = $endpoint
$env:REPO_SLUG       = $repo
$env:BRANCH          = $branch
$env:YAML_PATH       = $yamlPath
$env:API_BEARER      = $bearer

# 呼び出し先
$call = Join-Path $PSScriptRoot "call_register.ps1"
if (-not (Test-Path $call)) {
  Write-Error "call_register.ps1 が見つかりません。"
  Read-Host "Enterで終了"
  exit 1
}

# ログ開始
$logPath = Join-Path $PSScriptRoot "_runtime_log.txt"
Start-Transcript -Path $logPath -Append | Out-Null

try {
  Write-Host "エンドポイント: $endpoint" -ForegroundColor Cyan
  $res = & $call -endpoint $endpoint -bearer $bearer -repo $repo -branch $branch -path $yamlPath
  $res | Out-String | Write-Host
}
catch {
  Write-Error "実行中にエラー: $($_.Exception.Message)"
}
finally {
  Stop-Transcript | Out-Null
}

Read-Host "完了しました。Enterでこのウィンドウを閉じます"
