param()

function Ask($msg, $default = $null) {
  while ($true) {
    $q = if ($default) { "$msg [$default]" } else { $msg }
    $v = Read-Host $q
    if ([string]::IsNullOrWhiteSpace($v)) {
      if ($default) { return $default } else { Write-Host "This field is required." -ForegroundColor Yellow }
    } else { return $v }
  }
}
function AskSecret($msg) {
  while ($true) {
    $s = Read-Host $msg -AsSecureString
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    $v = [Runtime.InteropServices.Marshal]::PtrToStringAuto($b)
    if (-not [string]::IsNullOrWhiteSpace($v)) { return $v }
    Write-Host "This field is required." -ForegroundColor Yellow
  }
}

$endpoint = Ask "Vercel endpoint URL (e.g. https://your-app.vercel.app)"
$repo     = Ask "GitHub content repo (owner/repo)"
$branch   = Ask "Branch name" "main"
$yamlPath = Ask "YAML path" "characters.yaml"
$bearer   = AskSecret "API_BEARER (same as in Vercel env)"

$env:VERCEL_ENDPOINT = $endpoint
$env:REPO_SLUG       = $repo
$env:BRANCH          = $branch
$env:YAML_PATH       = $yamlPath
$env:API_BEARER      = $bearer

$call = Join-Path $PSScriptRoot "call_register.ps1"
if (-not (Test-Path $call)) {
  Write-Error "call_register.ps1 not found."
  Read-Host "Press Enter to exit"
  exit 1
}

$logPath = Join-Path $PSScriptRoot "_runtime_log.txt"
Start-Transcript -Path $logPath -Append | Out-Null
try {
  Write-Host "Endpoint: $endpoint" -ForegroundColor Cyan
  $res = & $call -endpoint $endpoint -bearer $bearer -repo $repo -branch $branch -path $yamlPath
  $res | Out-String | Write-Host
} catch {
  Write-Error "Error during execution: $($_.Exception.Message)"
} finally {
  Stop-Transcript | Out-Null
}

Read-Host "Done. Press Enter to close this window"
