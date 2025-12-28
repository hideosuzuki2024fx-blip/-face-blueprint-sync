param(
  [string]$RepoRoot = "E:\ai_dev_core",
  [int]$PollMs = 800
)

function Normalize([string]$p){
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $p = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($p) } catch { $p }
}

$repo = Normalize $RepoRoot
if ($repo -notlike "E:\*") { exit 1 }

Set-Location $repo
$top = Normalize (git rev-parse --show-toplevel 2>$null)
$inside = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top) { exit 1 }
if (-not [String]::Equals($top,$repo,[StringComparison]::OrdinalIgnoreCase)) { exit 1 }

$base = Join-Path $repo ".gitgpt"
$queueDir   = Join-Path $base "queue"
$resultsDir = Join-Path $base "results"
New-Item -ItemType Directory -Path $queueDir   -Force | Out-Null
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

function W([string]$txt,[string]$jobId){
  $hdr = "=== RESULT: $jobId ===`r`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
  $content = $hdr + $txt
  $last = Join-Path $base "last_result.txt"
  $out  = Join-Path $resultsDir ("{0}.txt" -f $jobId)
  $content | Set-Content -Path $last -Encoding UTF8
  $content | Set-Content -Path $out  -Encoding UTF8
}

function Do-Commit($msg,$paths){
  git add -- $paths | Out-Null
  if ($LASTEXITCODE -ne 0) { return "git add failed" }
  if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "chore: apply via daemon" }
  git commit -m $msg | Out-String
}
function Do-Push(){
  $head = (git rev-parse --abbrev-ref HEAD).Trim()
  $u = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
  $hasU = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($u)
  if ($hasU) { git push origin $head | Out-String } else { git push -u origin $head | Out-String }
}
function Do-Pull(){
  $cur = (git rev-parse --abbrev-ref HEAD).Trim()
  git fetch origin | Out-Null
  git pull origin $cur | Out-String
}
function Do-Status($paths){ git status --porcelain=v1 -- $paths | Out-String }
function Do-Diff($paths){   git diff --stat -- $paths | Out-String }

while ($true) {
  try {
    $jobs = Get-ChildItem -Path $queueDir -Filter *.json -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime
    foreach ($j in $jobs) {
      $jobId = [System.IO.Path]::GetFileNameWithoutExtension($j.Name)
      $raw = Get-Content $j.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($null -eq $raw) { Remove-Item $j.FullName -Force; continue }

      # セキュリティ
      if ($raw.repo -notlike "E:\*") { W "reject: repo must be under E:\" $jobId; Remove-Item $j.FullName -Force; continue }
      if ($raw.token -ne "承認")     { W "reject: invalid token" $jobId;            Remove-Item $j.FullName -Force; continue }

      Set-Location (Normalize $raw.repo)
      $top = Normalize (git rev-parse --show-toplevel 2>$null)
      $inside = git rev-parse --is-inside-work-tree 2>$null
      if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top) { W "reject: not a git repo" $jobId; Remove-Item $j.FullName -Force; continue }
      if (-not [String]::Equals($top,(Normalize $raw.repo),[StringComparison]::OrdinalIgnoreCase)) { W "reject: unexpected toplevel: $top" $jobId; Remove-Item $j.FullName -Force; continue }

      $intent = ($raw.intent ?? "").ToLower()
      $paths = @("."); if ($raw.paths) { $paths = @(); foreach($p in $raw.paths){ $paths += ($p -replace '/', '\') } }

      $out = switch ($intent) {
        "commit" { Do-Commit $raw.message $paths; break }
        "push"   { Do-Push; break }
        "pull"   { Do-Pull; break }
        "status" { Do-Status $paths; break }
        "diff"   { Do-Diff $paths; break }
        default  { "noop/unknown intent: $intent" }
      }

      W ($out | Out-String) $jobId
      Remove-Item $j.FullName -Force
    }
  } catch { }
  Start-Sleep -Milliseconds $PollMs
}
