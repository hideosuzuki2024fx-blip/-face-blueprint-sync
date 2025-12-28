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
function Mask($s) {
  if (-not $s) { return "<empty>" }
  $len = $s.Length; $head = if ($len -ge 4) { $s.Substring(0,4) } else { $s }
  return "$head*** (len=$len)"
}

if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
  Write-Error "vercel CLI not found. Install it via: npm i -g vercel"
  Read-Host "Press Enter to exit"
  exit 1
}

$proj = Ask "Vercel project name" "face-blueprint-sync"
Write-Host "Linking or creating project: $proj" -ForegroundColor Cyan
try {
  vercel link --project $proj --yes
} catch {
  Write-Error "vercel link failed: $($_.Exception.Message)"
  Read-Host "Press Enter to exit"
  exit 1
}

$apiBearer = AskSecret "Set API_BEARER (same value you will call from GPT/PS)"
$ghToken   = AskSecret "Set GITHUB_TOKEN (GitHub PAT with contents:write)"

try {
  vercel env rm API_BEARER production -y 2>$null
  vercel env rm GITHUB_TOKEN production -y 2>$null
  Write-Output $apiBearer | vercel env add API_BEARER production
  Write-Output $ghToken   | vercel env add GITHUB_TOKEN production
} catch {
  Write-Error "vercel env add failed: $($_.Exception.Message)"
  Read-Host "Press Enter to exit"
  exit 1
}

Write-Host "Deploying to production..." -ForegroundColor Cyan
$deployOut = vercel deploy --prod --yes --confirm --no-clipboard 2>&1 | Out-String
$endpoint = ($deployOut -split "`r?`n" | Where-Object { $_ -match '^https?://' } | Select-Object -Last 1).Trim()
if (-not $endpoint) { $endpoint = "UNKNOWN" }
$depFile = Join-Path (Split-Path $PSScriptRoot -Parent) "DEPLOY_ENDPOINT.txt"
Set-Content -Path $depFile -Value $endpoint -Encoding utf8
Write-Host "Endpoint: $endpoint" -ForegroundColor Green

# Optional quick test if call_register.ps1 exists
$call = Join-Path $PSScriptRoot "call_register.ps1"
if (Test-Path $call) {
  $repo   = Ask "GitHub content repo (owner/repo)"
  $branch = Ask "Branch name" "main"
  $path   = Ask "YAML path" "characters.yaml"
  $env:VERCEL_ENDPOINT = $endpoint
  $env:API_BEARER      = $apiBearer
  $env:REPO_SLUG       = $repo
  $env:BRANCH          = $branch
  $env:YAML_PATH       = $path
  try {
    Write-Host "Testing /api/register ..." -ForegroundColor Cyan
    $res = & $call -endpoint $endpoint -bearer $apiBearer -repo $repo -branch $branch -path $path
    $res | Out-String | Write-Host
  } catch {
    Write-Error "Test failed: $($_.Exception.Message)"
  }
} else {
  Write-Host "call_register.ps1 not found. Skip API test." -ForegroundColor Yellow
}

$log = @"
# Vercel new project setup (masked)
Project : $proj
Endpoint: $endpoint
API_BEARER: $(Mask($apiBearer))
GITHUB_TOKEN: $(Mask($ghToken))
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
"@
$logFile = Join-Path $PSScriptRoot "_vercel_new_project_log.txt"
$log | Out-File -FilePath $logFile -Encoding utf8 -Force

Read-Host "Done. Press Enter to close this window"
