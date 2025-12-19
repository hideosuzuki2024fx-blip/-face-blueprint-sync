param(
  [int]$Port = 8765
)

# ===== Utils =====
Add-Type -AssemblyName System.Web

function Normalize([string]$p){
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $p = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($p) } catch { $p }
}
function Ok([object]$data){ return @{ ok=$true;  data=$data } }
function Err([string]$msg,[int]$code=400){ return @{ ok=$false; error=$msg; code=$code } }

function JsonResponse([object]$obj,[System.Net.HttpListenerResponse]$resp,[int]$status=200){
  $json = ($obj | ConvertTo-Json -Depth 8 -Compress)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $resp.StatusCode = $status
  $resp.ContentType = "application/json; charset=utf-8"
  $resp.Headers["Access-Control-Allow-Origin"] = "*"
  $resp.Headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  $resp.Headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
  $resp.OutputStream.Write($bytes,0,$bytes.Length)
  $resp.Close()
}

function Read-Json([System.IO.Stream]$s){
  try {
    $r = New-Object System.IO.StreamReader($s,[System.Text.Encoding]::UTF8)
    $body = $r.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($body)) { return $null }
    return ($body | ConvertFrom-Json -ErrorAction Stop)
  } catch {
    return $null
  }
}

function Ensure-GitRepo([string]$repo){
  if ($repo -notlike "E:\*") { throw "E:\ 配下のみ許可: $repo" }
  Set-Location $repo
  $top = Normalize (git rev-parse --show-toplevel 2>$null)
  $inside = git rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top){ throw "Git 管理下ではありません: $repo" }
  if (-not [String]::Equals($top,(Normalize $repo),[StringComparison]::OrdinalIgnoreCase)){ throw "想定外のtoplevel: $top" }
}

function Run-Git([string[]]$args){
  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName = "git"
  $pinfo.RedirectStandardOutput = $true
  $pinfo.RedirectStandardError  = $true
  $pinfo.UseShellExecute = $false
  $pinfo.Arguments = ($args -join " ")
  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $pinfo
  [void]$proc.Start()
  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  return @{ code=$proc.ExitCode; stdout=$stdout; stderr=$stderr }
}

# ===== Handlers =====
function H-Status($b){
  if ($b.token -ne "承認") { return Err "invalid token" 403 }
  $repo  = Normalize $b.repo
  Ensure-GitRepo $repo
  $paths = @("."); if ($b.paths){ $paths = @(); foreach($p in $b.paths){ $paths += ($p -replace '/', '\') } }
  $r = Run-Git @("status","--porcelain=v1","--") + $paths
  if ($r.code -eq 0){ return Ok @{ repo=$repo; status=$r.stdout } } else { return Err $r.stderr 500 }
}
function H-Diff($b){
  if ($b.token -ne "承認") { return Err "invalid token" 403 }
  $repo  = Normalize $b.repo
  Ensure-GitRepo $repo
  $paths = @("."); if ($b.paths){ $paths = @(); foreach($p in $b.paths){ $paths += ($p -replace '/', '\') } }
  $r = Run-Git @("diff","--stat","--") + $paths
  if ($r.code -eq 0){ return Ok @{ repo=$repo; diffstat=$r.stdout } } else { return Err $r.stderr 500 }
}
function H-Commit($b){
  if ($b.token -ne "承認") { return Err "invalid token" 403 }
  $repo   = Normalize $b.repo
  Ensure-GitRepo $repo
  $paths = @("."); if ($b.paths){ $paths = @(); foreach($p in $b.paths){ $paths += ($p -replace '/', '\') } }
  $msg = [string]$b.message
  if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "chore: apply via httpd" }
  $r1 = Run-Git @("add","--") + $paths
  if ($r1.code -ne 0){ return Err $r1.stderr 500 }
  $r2 = Run-Git @("commit","-m",('"{0}"' -f $msg))
  if ($r2.code -eq 0){ return Ok @{ repo=$repo; commit=$r2.stdout } } else { return Err $r2.stderr 500 }
}
function H-Push($b){
  if ($b.token -ne "承認") { return Err "invalid token" 403 }
  $repo  = Normalize $b.repo
  Ensure-GitRepo $repo
  $head = (git rev-parse --abbrev-ref HEAD).Trim()
  $u = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
  $hasU = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($u)
  $args = @("push","-v","origin",$head)
  if (-not $hasU){ $args = @("push","-u","-v","origin",$head) }
  $r = Run-Git $args
  if ($r.code -eq 0){ return Ok @{ repo=$repo; push=$r.stdout } } else { return Err $r.stderr 500 }
}
function H-Pull($b){
  if ($b.token -ne "承認") { return Err "invalid token" 403 }
  $repo  = Normalize $b.repo
  Ensure-GitRepo $repo
  $cur = (git rev-parse --abbrev-ref HEAD).Trim()
  [void](Run-Git @("fetch","origin"))
  $r = Run-Git @("pull","origin",$cur)
  if ($r.code -eq 0){ return Ok @{ repo=$repo; pull=$r.stdout } } else { return Err $r.stderr 500 }
}

# ===== HTTP Server =====
$prefix = "http://127.0.0.1:{0}/" -f $Port
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try { $listener.Start() }
catch {
  # URL ACL が未登録の可能性
  Write-Host "URLACL を追加します: $prefix"
  try {
    $user = "$env:USERDOMAIN\$env:USERNAME"
    Start-Process -FilePath "netsh" -ArgumentList @("http","add","urlacl","url=$prefix","user=$user") -Verb RunAs -Wait
    $listener.Start()
  } catch {
    Write-Error "HttpListener が起動できません。管理者権限で一度実行して URLACL 登録が必要です。"
    exit 1
  }
}

Write-Host "[gitgpt_locald] listening at $prefix"
while ($true) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    if ($req.HttpMethod -eq "OPTIONS") {
      $res.Headers["Access-Control-Allow-Origin"] = "*"
      $res.Headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
      $res.Headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
      $res.StatusCode = 204
      $res.Close()
      continue
    }

    $path = $req.Url.AbsolutePath.ToLower()
    $body = Read-Json $req.InputStream
    if ($null -eq $body) { JsonResponse (Err "invalid json") $res 400; continue }

    $result = switch ($path) {
      "/status" { H-Status $body; break }
      "/diff"   { H-Diff   $body; break }
      "/commit" { H-Commit $body; break }
      "/push"   { H-Push   $body; break }
      "/pull"   { H-Pull   $body; break }
      default   { Err ("unknown path: {0}" -f $path) 404 }
    }

    if ($result.ok) { JsonResponse $result $res 200 } else { JsonResponse $result $res ($result.code) }
  } catch {
    try { JsonResponse (Err $_.Exception.Message 500) $res 500 } catch {}
  }
}
