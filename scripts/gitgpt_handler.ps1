param([Parameter(Mandatory=$true)][string]$Url)

Add-Type -AssemblyName System.Web
function Write-Result([string]$text, [string]$repo, [string]$label) {
  try {
    $outDir = Join-Path $repo ".gitgpt"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $outFile = Join-Path $outDir "last_result.txt"
    $header = "=== RESULT: $label ===`r`n" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "`r`n`r`n"
    ($header + $text) | Set-Content -Path $outFile -Encoding UTF8
    try { ($header + $text) | Set-Clipboard } catch {}
    Start-Process -FilePath "notepad.exe" -ArgumentList "`"$outFile`""
  } catch {
    Write-Host "結果の保存/表示に失敗: $(param([Parameter(Mandatory=$true)][string]$Url)

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

switch ($action.ToLower()) {
  "status" {
    # 既存: status/diff もある想定。ここで op=list_repos をハンドル
    $op   = if ($p.ContainsKey("op")) { $p["op"] } else { "" }
    if ($op -eq "list_repos") {
      $root = if ($p["root"]) { $p["root"] } else { "E:\" }
      $ap   = if ($p["ap"])   { $p["ap"] } else { "0" }
      # 正規化と E:\ 制限
      $root = $root -replace '/', '\'
      try { $root = [System.IO.Path]::GetFullPath($root) } catch {}
      if ($root -notlike "E:\*") { Write-Error "E:\ 配下のみ許可"; exit 1 }

      $depth = 3
      if ($p["depth"] -and ($p["depth"] -match '^\d+
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
.Exception.Message)"
  }
}

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

function AutoPost-Result([string]$text) {
  try {
    # クリップボード
    try { $text | Set-Clipboard } catch {}
    # アクティブウィンドウへ貼付→送信（Ctrl+V, Enter）
    $ws = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 150
    $ws.SendKeys("^{v}")
    Start-Sleep -Milliseconds 100
    $ws.SendKeys("~")  # Enter
  } catch {
    Write-Host "自動貼り付けに失敗: $($_.Exception.Message)"
  }
})) { $depth = [int]$p["depth"] }

      $sb = New-Object System.Text.StringBuilder
      $null = $sb.AppendLine("root: " + $root)
      $null = $sb.AppendLine("depth: " + $depth)
      $null = $sb.AppendLine("----- repositories under root -----")

      $repos = @()
      try {
        $gits = Get-ChildItem -Path $root -Recurse -Directory -Depth $depth -Filter ".git" -Force 2>$null
        foreach ($g in $gits) {
          $repo = [System.IO.Path]::GetFullPath((Split-Path -Parent $g.FullName) -replace '/', '\')
          if ($repo -and ($repos -notcontains $repo)) { $repos += $repo }
        }
      } catch {
        $null = $sb.AppendLine("scan failed: $(param([Parameter(Mandatory=$true)][string]$Url)

Add-Type -AssemblyName System.Web
function Write-Result([string]$text, [string]$repo, [string]$label) {
  try {
    $outDir = Join-Path $repo ".gitgpt"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $outFile = Join-Path $outDir "last_result.txt"
    $header = "=== RESULT: $label ===`r`n" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "`r`n`r`n"
    ($header + $text) | Set-Content -Path $outFile -Encoding UTF8
    try { ($header + $text) | Set-Clipboard } catch {}
    Start-Process -FilePath "notepad.exe" -ArgumentList "`"$outFile`""
  } catch {
    Write-Host "結果の保存/表示に失敗: $(param([Parameter(Mandatory=$true)][string]$Url)

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
.Exception.Message)"
  }
}

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

function AutoPost-Result([string]$text) {
  try {
    # クリップボード
    try { $text | Set-Clipboard } catch {}
    # アクティブウィンドウへ貼付→送信（Ctrl+V, Enter）
    $ws = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 150
    $ws.SendKeys("^{v}")
    Start-Sleep -Milliseconds 100
    $ws.SendKeys("~")  # Enter
  } catch {
    Write-Host "自動貼り付けに失敗: $($_.Exception.Message)"
  }
}.Exception.Message)")
      }

      if ($repos.Count -eq 0) { $null = $sb.AppendLine("(none)"); Write-Result $sb.ToString() $repo "list_repos"; if ($ap -eq "1") { AutoPost-Result $sb.ToString() }; exit 0 }

      $idx = 0
      foreach ($r in $repos) {
        # 埋め込み/サブモジュール風の簡易判定: .git が「ファイル」ならサブモジュール、ディレクトリなら通常
        $gitPath = Join-Path $r ".git"
        $kind = "(dir)"
        if (Test-Path $gitPath) {
          $gi = Get-Item $gitPath -Force
          if (-not $gi.PSIsContainer) { $kind = "(submodule-like)" }
        }
        $null = $sb.AppendLine( ("[{0}] {1} {2}" -f $idx, $r, $kind) )
        $idx++
      }

      Write-Result $sb.ToString() $repo "list_repos"
      if ($ap -eq "1") { AutoPost-Result $sb.ToString() }
      exit 0
    }

    # 既存の status/diff などの処理にフォールバック
    # （元の status 分岐処理は既存コードをそのまま使用）
  }
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
.Exception.Message)"
  }
}

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

switch ($action.ToLower()) {
  "status" {
    # 既存: status/diff もある想定。ここで op=list_repos をハンドル
    $op   = if ($p.ContainsKey("op")) { $p["op"] } else { "" }
    if ($op -eq "list_repos") {
      $root = if ($p["root"]) { $p["root"] } else { "E:\" }
      $ap   = if ($p["ap"])   { $p["ap"] } else { "0" }
      # 正規化と E:\ 制限
      $root = $root -replace '/', '\'
      try { $root = [System.IO.Path]::GetFullPath($root) } catch {}
      if ($root -notlike "E:\*") { Write-Error "E:\ 配下のみ許可"; exit 1 }

      $depth = 3
      if ($p["depth"] -and ($p["depth"] -match '^\d+
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

function AutoPost-Result([string]$text) {
  try {
    # クリップボード
    try { $text | Set-Clipboard } catch {}
    # アクティブウィンドウへ貼付→送信（Ctrl+V, Enter）
    $ws = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 150
    $ws.SendKeys("^{v}")
    Start-Sleep -Milliseconds 100
    $ws.SendKeys("~")  # Enter
  } catch {
    Write-Host "自動貼り付けに失敗: $($_.Exception.Message)"
  }
})) { $depth = [int]$p["depth"] }

      $sb = New-Object System.Text.StringBuilder
      $null = $sb.AppendLine("root: " + $root)
      $null = $sb.AppendLine("depth: " + $depth)
      $null = $sb.AppendLine("----- repositories under root -----")

      $repos = @()
      try {
        $gits = Get-ChildItem -Path $root -Recurse -Directory -Depth $depth -Filter ".git" -Force 2>$null
        foreach ($g in $gits) {
          $repo = [System.IO.Path]::GetFullPath((Split-Path -Parent $g.FullName) -replace '/', '\')
          if ($repo -and ($repos -notcontains $repo)) { $repos += $repo }
        }
      } catch {
        $null = $sb.AppendLine("scan failed: $(param([Parameter(Mandatory=$true)][string]$Url)

Add-Type -AssemblyName System.Web
function Write-Result([string]$text, [string]$repo, [string]$label) {
  try {
    $outDir = Join-Path $repo ".gitgpt"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $outFile = Join-Path $outDir "last_result.txt"
    $header = "=== RESULT: $label ===`r`n" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "`r`n`r`n"
    ($header + $text) | Set-Content -Path $outFile -Encoding UTF8
    try { ($header + $text) | Set-Clipboard } catch {}
    Start-Process -FilePath "notepad.exe" -ArgumentList "`"$outFile`""
  } catch {
    Write-Host "結果の保存/表示に失敗: $(param([Parameter(Mandatory=$true)][string]$Url)

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
.Exception.Message)"
  }
}

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

function AutoPost-Result([string]$text) {
  try {
    # クリップボード
    try { $text | Set-Clipboard } catch {}
    # アクティブウィンドウへ貼付→送信（Ctrl+V, Enter）
    $ws = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 150
    $ws.SendKeys("^{v}")
    Start-Sleep -Milliseconds 100
    $ws.SendKeys("~")  # Enter
  } catch {
    Write-Host "自動貼り付けに失敗: $($_.Exception.Message)"
  }
}.Exception.Message)")
      }

      if ($repos.Count -eq 0) { $null = $sb.AppendLine("(none)"); Write-Result $sb.ToString() $repo "list_repos"; if ($ap -eq "1") { AutoPost-Result $sb.ToString() }; exit 0 }

      $idx = 0
      foreach ($r in $repos) {
        # 埋め込み/サブモジュール風の簡易判定: .git が「ファイル」ならサブモジュール、ディレクトリなら通常
        $gitPath = Join-Path $r ".git"
        $kind = "(dir)"
        if (Test-Path $gitPath) {
          $gi = Get-Item $gitPath -Force
          if (-not $gi.PSIsContainer) { $kind = "(submodule-like)" }
        }
        $null = $sb.AppendLine( ("[{0}] {1} {2}" -f $idx, $r, $kind) )
        $idx++
      }

      Write-Result $sb.ToString() $repo "list_repos"
      if ($ap -eq "1") { AutoPost-Result $sb.ToString() }
      exit 0
    }

    # 既存の status/diff などの処理にフォールバック
    # （元の status 分岐処理は既存コードをそのまま使用）
  }
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

function AutoPost-Result([string]$text) {
  try {
    # クリップボード
    try { $text | Set-Clipboard } catch {}
    # アクティブウィンドウへ貼付→送信（Ctrl+V, Enter）
    $ws = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 150
    $ws.SendKeys("^{v}")
    Start-Sleep -Milliseconds 100
    $ws.SendKeys("~")  # Enter
  } catch {
    Write-Host "自動貼り付けに失敗: $($_.Exception.Message)"
  }
}

function Wait-And-Show-LastResult([string]$repo, [string]$ap, [int]$timeoutSec = 20) {
  $last = Join-Path $repo ".gitgpt\last_result.txt"
  $startUtc = $null
  if (Test-Path $last) {
    try { $startUtc = (Get-Item $last -ErrorAction SilentlyContinue).LastWriteTimeUtc } catch {}
  }
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 300
    $fi = Get-Item $last -ErrorAction SilentlyContinue
    if ($fi -and (-not $startUtc -or $fi.LastWriteTimeUtc -gt $startUtc)) {
      $text = Get-Content $last -Raw -Encoding UTF8
      try { $text | Set-Clipboard } catch {}
      Start-Process -FilePath "notepad.exe" -ArgumentList "`"$last`""
      if ($ap -eq "1") { AutoPost-Result $text }
      return
    }
  }
}
