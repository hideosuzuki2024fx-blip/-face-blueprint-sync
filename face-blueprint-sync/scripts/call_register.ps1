param(
  [string]$endpoint,
  [string]$bearer  = $env:API_BEARER,
  [string]$repo    = $env:REPO_SLUG,   # e.g. owner/face-blueprint-content
  [string]$branch  = $env:BRANCH,      # e.g. main
  [string]$path    = $env:YAML_PATH    # e.g. characters.yaml
)

# エンドポイントの解決: 引数 > DEPLOY_ENDPOINT.txt > 環境変数
if (-not $endpoint) {
  $depFile = Join-Path $PSScriptRoot "..\DEPLOY_ENDPOINT.txt"
  if (Test-Path $depFile) {
    $endpoint = (Get-Content -Path $depFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
  } elseif ($env:VERCEL_ENDPOINT) {
    $endpoint = $env:VERCEL_ENDPOINT
  }
}

if (-not $endpoint -or $endpoint -eq '' -or $endpoint -eq 'UNKNOWN') {
  Write-Error "エンドポイント不明です。-endpoint で指定するか、DEPLOY_ENDPOINT.txt / VERCEL_ENDPOINT を設定してください。"
  exit 1
}
if (-not $bearer) { Write-Error "API_BEARER が未設定です。"; exit 1 }
if (-not $repo)   { Write-Error "REPO_SLUG が未設定です。"; exit 1 }
if (-not $branch) { Write-Error "BRANCH が未設定です。"; exit 1 }
if (-not $path)   { Write-Error "YAML_PATH が未設定です。"; exit 1 }

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
    always_add = @(
      "portrait photo",
      "imaginary adult woman",
      "same face identity",
      "photorealistic",
      "cinematic natural lighting",
      "shallow depth of field"
    )
  }
} | ConvertTo-Json -Depth 8

$uri = ($endpoint.TrimEnd('/') + '/api/register')
Write-Host "POST -> $uri"
$result = Invoke-RestMethod -Method POST -Uri $uri `
  -Headers @{ Authorization = "Bearer $bearer"; "content-type" = "application/json" } `
  -Body $payload

$result | ConvertTo-Json -Depth 8
