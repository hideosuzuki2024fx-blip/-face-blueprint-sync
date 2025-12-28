param(
  [string]$endpoint,
  [string]$bearer,
  [string]$repo,
  [string]$branch,
  [string]$path
)

function Get-Ascii([string]$s) {
  if (-not $s) { return $s }
  $ascii = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($s))
  if ($ascii -ne $s) { throw "Header contains non-ASCII characters. Use pure ASCII token." }
  return $ascii
}
function CleanHeader([string]$s) {
  if (-not $s) { return $s }
  $s = $s -replace "[`r`n]", ""   # 改行除去
  $s = $s.Trim()
  $s = Get-Ascii $s
  return $s
}

if (-not $endpoint) {
  $dep = Join-Path $PSScriptRoot "..\DEPLOY_ENDPOINT.txt"
  if (Test-Path $dep) { $endpoint = (Get-Content $dep | Select-Object -First 1).Trim() }
  elseif ($env:VERCEL_ENDPOINT) { $endpoint = $env:VERCEL_ENDPOINT }
}
if (-not $bearer) { $bearer = $env:API_BEARER }
if (-not $repo)   { $repo   = $env:REPO_SLUG }
if (-not $branch) { $branch = $env:BRANCH }
if (-not $path)   { $path   = $env:YAML_PATH }

if ([string]::IsNullOrWhiteSpace($endpoint) -or $endpoint -eq "UNKNOWN") { Write-Error "Endpoint unknown"; exit 1 }
if ([string]::IsNullOrWhiteSpace($bearer)) { Write-Error "API_BEARER not set"; exit 1 }
if ([string]::IsNullOrWhiteSpace($repo))   { Write-Error "REPO_SLUG not set"; exit 1 }
if ([string]::IsNullOrWhiteSpace($branch)) { Write-Error "BRANCH not set"; exit 1 }
if ([string]::IsNullOrWhiteSpace($path))   { Write-Error "YAML_PATH not set"; exit 1 }

$bearer = CleanHeader $bearer

$payload = @{
  op = "append_character"
  repo = $repo
  branch = $branch
  path = $path
  merge_strategy = "append"
  create_pr = $true
  pr_branch = "auto/character-MAYA"
  commit_message = "chore: add character MAYA"
  character = @{
    name = "MAYA"
    description = "soft feminine gravure model"
    face_blueprint = @{
      age = "adult"
      face_shape = "soft oval, slightly heart-shaped"
      jawline = "smooth, rounded"
      cheekbones = "moderately high, gentle fullness"
      skin = "fair to light warm tone, natural texture"
      eyes = "medium almond-shaped, calm expression"
      eye_color = "hazel to light brown"
      eyebrows = "medium thickness, soft natural arch"
      nose = "small to medium, straight bridge, rounded tip"
      lips = "medium-full, natural curve"
      hair = @{ color="warm blonde"; length="shoulder-length"; style="soft straight or gentle waves"; part="center or slight side part" }
    }
    always_add = @("portrait photo","imaginary adult woman","same face identity","photorealistic","cinematic natural lighting","shallow depth of field")
  }
} | ConvertTo-Json -Depth 8

$uri = ($endpoint.TrimEnd('/') + "/api/register")
Write-Host "POST -> $uri"
$result = Invoke-RestMethod -Method POST -Uri $uri `
  -Headers @{ Authorization = ("Bearer " + $bearer) } `
  -ContentType "application/json" `
  -Body $payload

$result | ConvertTo-Json -Depth 8
