# gitgpt_handler.ps1
# 目的: gitgpt:// URL からローカル Git 操作をトリガー
#       (承認トークン必須, queue=1 で daemon に投入, await=1 で結果待機)

param([string]$url)

Add-Type -AssemblyName System.Web

function Parse-Query([string]$query) {
  $r = @{}
  if ([string]::IsNullOrWhiteSpace($query)) { return $r }
  foreach ($kv in ($query -split '&')) {
    if (-not $kv) { continue }
    $pair = $kv.Split('=',2)
    $k = [System.Web.HttpUtility]::UrlDecode($pair[0])
    $v = if ($pair.Count -gt 1) { [System.Web.HttpUtility]::UrlDecode($pair[1]) } else { "" }
    $r[$k] = $v
  }
  return $r
}

function Normalize([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $p = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($p) } catch { $p }
}

function Enqueue-Job([string]$repo,[string]$intent,[hashtable]$payload){
  $base = Join-Path $repo ".gitgpt"
  $q = Join-Path $base "queue"
  New-Item -ItemType Directory -Path $q -Force | Out-Null
  $id = (Get-Date -Format "yyyyMMdd_HHmmss_fff") + "_" + $intent
  $job = @{
    repo    = $repo
    intent  = $intent
    token   = $payload["token"]
    message = $payload["msg"]
    paths   = $payload["paths"]
  } | ConvertTo-Json -Depth 5
  $path = Join-Path $q ($id + ".json")
  $job | Set-Content -Path $path -Encoding UTF8
  return $id
}

function Wait-And-Show-LastResult([string]$repo,[string]$ap,[int]$timeoutSec=20){
  $last = Join-Path $repo ".gitgpt\last_result.txt"
  $start = $null
  if (Test-Path $last) { $start = (Get-Item $last).LastWriteTimeUtc }
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 300
    $fi = Get-Item $last -ErrorAction SilentlyContinue
    if ($fi -and (-not $start -or $fi.LastWriteTimeUtc -gt $start)) {
      $text = Get-Content $last -Raw -Encoding UTF8
      Start-Process -FilePath "notepad.exe" -ArgumentList "`"$last`""
      if ($ap -eq "1") { try { $text | Set-Clipboard } catch {} }
      return
    }
  }
}

# --- URL解析 ---
if ($url -notmatch '^gitgpt://') {
  Write-Error "invalid scheme"; exit 1
}

$u = $url.Substring(9)
$parts = $u.Split('?',2)
$action = $parts[0]
$q = if ($parts.Count -gt 1) { $parts[1] } else { "" }
$p = Parse-Query $q

$repo   = Normalize $p["repo"]
$token  = $p["t"]
$msg    = $p["msg"]
$paths  = if ($p["paths"]) { @($p["paths"].Split(",")) } else { @(".") }
$queue  = $p["queue"]
$await  = $p["await"]
$ap     = $p["ap"]

Write-Host "=== PLAN ==="
Write-Host "action : $action"
Write-Host "repo   : $repo"

# --- 動作 ---
switch ($action) {
  "apply" {
    if ($queue -eq "1") {
      $payload = @{ token=$token; msg=$msg; paths=$paths }
      $jid = Enqueue-Job $repo "commit" $payload
      Write-Host "enqueued: $jid"
      if ($await -eq "1") { Wait-And-Show-LastResult $repo $ap }
      exit 0
    }
  }
  "push" {
    if ($queue -eq "1") {
      $payload = @{ token=$token; msg=""; paths=$paths }
      $jid = Enqueue-Job $repo "push" $payload
      Write-Host "enqueued: $jid"
      if ($await -eq "1") { Wait-And-Show-LastResult $repo $ap }
      exit 0
    }
  }
  "pull" {
    if ($queue -eq "1") {
      $payload = @{ token=$token; msg=""; paths=$paths }
      $jid = Enqueue-Job $repo "pull" $payload
      Write-Host "enqueued: $jid"
      if ($await -eq "1") { Wait-And-Show-LastResult $repo $ap }
      exit 0
    }
  }
  "status" {
    if ($queue -eq "1") {
      $payload = @{ token=$token; msg=""; paths=$paths }
      $jid = Enqueue-Job $repo "status" $payload
      Write-Host "enqueued: $jid"
      if ($await -eq "1") { Wait-And-Show-LastResult $repo $ap }
      exit 0
    }
  }
  "diff" {
    if ($queue -eq "1") {
      $payload = @{ token=$token; msg=""; paths=$paths }
      $jid = Enqueue-Job $repo "diff" $payload
      Write-Host "enqueued: $jid"
      if ($await -eq "1") { Wait-And-Show-LastResult $repo $ap }
      exit 0
    }
  }
  default { Write-Host "Unknown action: $action" }
}
