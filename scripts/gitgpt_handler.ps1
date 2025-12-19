param([Parameter(Mandatory=$true)][string]$Url)

Add-Type -AssemblyName System.Web

function Normalize([string]$p){
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  $p = $p -replace '/', '\'
  try { [System.IO.Path]::GetFullPath($p) } catch { $p }
}
function Q([string]$q){
  $m=@{}; if ($q.StartsWith("?")){$q=$q.Substring(1)}
  foreach($kv in $q -split "&"){ if(-not $kv){continue}
    $p=$kv -split "=",2
    $k=[System.Web.HttpUtility]::UrlDecode($p[0])
    $v= if($p.Length -gt 1){[System.Web.HttpUtility]::UrlDecode($p[1])} else {""}
    $m[$k]=$v
  }; $m
}

$u=[Uri]$Url
if ($u.Scheme -ne "gitgpt"){ Write-Error "未知のスキーム: $($u.Scheme)"; exit 1 }
$action=$u.Host   # apply/push/pull
$p=Q $u.Query

$repo=Normalize ($p["repo"])
$token=$p["t"]
if ([string]::IsNullOrWhiteSpace($repo)){ Write-Error "repo 未指定"; exit 1 }
if ($repo -notlike "E:\*"){ Write-Error "E:\ 配下のみ許可"; exit 1 }
if ($token -ne "承認"){ Write-Host "承認トークン不一致。終了。"; exit 2 }

Set-Location $repo
$top=Normalize (git rev-parse --show-toplevel 2>$null)
$inside=git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or -not $inside -or -not $top){ Write-Error "Git 管理外"; exit 1 }
if (-not [String]::Equals($top,(Normalize $repo),[StringComparison]::OrdinalIgnoreCase)){
  Write-Error "想定外のパス: $top"; exit 1
}

switch ($action.ToLower()){
  "apply" {
    $msg = $p["msg"]; if ([string]::IsNullOrWhiteSpace($msg)){ $msg="chore: apply via gitgpt" }
    $paths = @(".")
    if ($p.ContainsKey("paths")){ $paths = ($p["paths"] -split ",") | ForEach-Object { $_.Trim() -replace '/', '\' } }
    Write-Host "=== PLAN ==="; git status --porcelain=v1 -- $paths; git diff --stat -- $paths
    Write-Host "`n=== APPLY (add/commit) ==="
    git add -- $paths; if ($LASTEXITCODE -ne 0){ exit $LASTEXITCODE }
    git commit -m $msg; exit $LASTEXITCODE
  }
  "push" {
    $remote = if($p["remote"]){$p["remote"]} else {"origin"}
    $branch = if($p["branch"]){$p["branch"]} else {(git rev-parse --abbrev-ref HEAD).Trim()}
    $upline = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    $hasU = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($upline)
    Write-Host "=== PLAN (push) ==="
    if ($hasU){ git log --oneline "$upline..HEAD" -n 50 } else { Write-Host "upstream: (none; will set)"; git log --oneline -n 50 }
    Write-Host "`n=== APPLY (push) ==="
    if ($hasU){ git push $remote $branch } else { git push -u $remote $branch }
    exit $LASTEXITCODE
  }
  "pull" {
    $remote= if($p["remote"]){$p["remote"]} else {"origin"}
    $branch= if($p["branch"]){$p["branch"]} else {(git rev-parse --abbrev-ref HEAD).Trim()}
    Write-Host "=== APPLY (pull) ==="
    git fetch $remote; git pull $remote $branch; exit $LASTEXITCODE
  }
  default { Write-Error "未知アクション: $action"; exit 1 }
}
