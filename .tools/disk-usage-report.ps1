# ============================================================
#  劲爆演示 2 / 4  —  硬链接刷量：让 8 KB 变成 10 万个文件
#  ------------------------------------------------------------
#  来自 Break-This-Repo 的真实现象：
#    · 1.05 GiB / 148,955 个条目 / 45.2% 是 0 字节文件
#    · GitHub 首页只显示体积 —— 那 45% 在访客眼里不存在
#
#  这个脚本证明「体积」和「文件数」可以完全脱钩，并给出：
#    A. NTFS 的真实硬链接上限（一个惊喜数字）
#    B. 同一个目录，各种工具数出来的不同答案 + 「大小」的四种含义
#    C. 交给 git 之后真正爆炸的是什么
#
#  安全性：全部在 $Root 目录内。跑完自动清理。
# ============================================================

param(
  [string]$Root    = "E:\_btr-hardlink-demo",
  [int]$Target     = 10000,
  [int]$Sources    = 12,
  [int]$PayloadKB  = 4,
  [int]$MaxPerSrc  = 1100,
  [switch]$Keep
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
function Line { param($c='-') Write-Host ($c * 84) -ForegroundColor DarkGray }
function Head { param($t) Write-Host ""; Line '='; Write-Host "  $t" -ForegroundColor Cyan; Line '=' }
function Sub  { param($t) Write-Host ""; Write-Host "  -- $t" -ForegroundColor DarkCyan }
function Bytes { param($b) if ($b -ge 1GB) { "{0:N2} GB" -f ($b/1GB) } elseif ($b -ge 1MB) { "{0:N2} MB" -f ($b/1MB) } elseif ($b -ge 1KB) { "{0:N1} KB" -f ($b/1KB) } else { "$b B" } }

if (Test-Path -LiteralPath $Root) { Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $Root | Out-Null
Write-Host "  沙箱: $Root" -ForegroundColor DarkGray

# ---------- 载体 ----------
Head "阶段 A : 造载体 + 硬链接轰炸"
$srcDir  = Join-Path $Root 'src'
$linkDir = Join-Path $Root 'links'
New-Item -ItemType Directory -Force -Path $srcDir, $linkDir | Out-Null

$rnd = New-Object Random 42
$payloadTotal = 0L
$srcPaths = New-Object 'System.Collections.Generic.List[string]'
foreach ($i in 1..$Sources) {
  $b = New-Object byte[] ($PayloadKB * 1024)
  $rnd.NextBytes($b)
  $p = Join-Path $srcDir ("carrier_{0:D3}.bin" -f $i)
  [IO.File]::WriteAllBytes($p, $b)
  $srcPaths.Add($p)
  $payloadTotal += $b.Length
}
Write-Host ("  {0} 个载体文件，共 {1}（随机数据，不可压缩）" -f $Sources, (Bytes $payloadTotal)) -ForegroundColor Yellow

Add-Type -Namespace BTR -Name HL -MemberDefinition @'
  [DllImport("Kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  public static extern bool CreateHardLink(string lpFileName, string lpExistingFileName, IntPtr lpSecurityAttributes);
'@ -ErrorAction Stop

Sub "先撞一次 NTFS 的单文件硬链接上限"
$probe = Join-Path $Root 'probe'
New-Item -ItemType Directory -Force -Path $probe | Out-Null
$n = 0; $errCode = 0
while ($n -le 5000) {
  if ([BTR.HL]::CreateHardLink((Join-Path $probe "p$n"), $srcPaths[0], [IntPtr]::Zero)) { $n++ }
  else { $errCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error(); break }
}
$errName = if ($errCode -eq 1142) { 'ERROR_TOO_MANY_LINKS (1142)' } elseif ($errCode -eq 0) { '未触发' } else { "Win32 错误 $errCode" }
Write-Host ("    单个文件最多 {0} 个硬链接 → {1}" -f $n, $errName) -ForegroundColor Magenta
$singleLimit = $n
Remove-Item -LiteralPath $probe -Recurse -Force -ErrorAction SilentlyContinue

Sub "用 $Sources 个载体绕过上限，冲向 $Target 个文件"
$sw = [Diagnostics.Stopwatch]::StartNew()
$ok = 0; $fail = 0; $si = 0; $perSrc = 0; $idx = 0
while ($ok -lt $Target -and $si -lt $srcPaths.Count) {
  if ($perSrc -ge $MaxPerSrc) { $si++; $perSrc = 0; continue }
  $name = Join-Path $linkDir ("许家印{0}.txt" -f $idx)
  if ([BTR.HL]::CreateHardLink($name, $srcPaths[$si], [IntPtr]::Zero)) { $ok++; $perSrc++; $idx++ }
  else { $fail++; $si++; $perSrc = 0 }
  if ($ok -gt 0 -and $ok % 500 -eq 0) {
    $el = $sw.Elapsed.TotalSeconds
    $pct = [int](100 * $ok / $Target)
    $bar = ('#' * [int]($pct / 2.5)) + ('.' * (40 - [int]($pct / 2.5)))
    Write-Host ("`r  [$bar] {0,3}%  {1,7:N0}/{2:N0}  {3,7:N0}/秒  {4,5:N1}s" -f $pct, $ok, $Target, ($ok/[Math]::Max($el,0.001)), $el) -NoNewline
  }
}
Write-Host ""
Write-Host ("  成功 {0:N0} / 失败 {1:N0} / 耗时 {2:N1} 秒" -f $ok, $fail, $sw.Elapsed.TotalSeconds) -ForegroundColor Green

# ---------- 计数器的分歧 ----------
Head "阶段 B : 同一个目录，谁数出多少"
$probeTar = Join-Path $env:TEMP '_btr_hl_probe.tar'
& tar -cf $probeTar -C $linkDir . 2>$null | Out-Null
$tarCount = @(& tar -tf $probeTar 2>$null).Count
Remove-Item $probeTar -Force -ErrorAction SilentlyContinue

$logical = 0L
foreach ($f in [IO.Directory]::GetFiles($linkDir)) { $logical += (New-Object IO.FileInfo $f).Length }

$counters = [ordered]@{
  '文件系统实际条目 (API)'    = @([IO.Directory]::GetFiles($linkDir)).Count
  'cmd dir /b'               = @(cmd /c "dir /b /a `"$linkDir`"").Count
  'PowerShell Get-ChildItem' = @(Get-ChildItem -LiteralPath $linkDir -Force -ErrorAction SilentlyContinue).Count
  'tar 打包条目数'            = $tarCount
}
Write-Host ("  {0,-28} {1,12}" -f '工具','条目数') -ForegroundColor White
Line
foreach ($k in $counters.Keys) { Write-Host ("  {0,-28} {1,12:N0}" -f $k, $counters[$k]) -ForegroundColor Gray }
Line

Sub "「大小」这个指标在同一批文件上的四种答案"
$ratio = $logical / [Math]::Max($payloadTotal,1)
$rows = @(
  [pscustomobject]@{ 指标='真实数据（载体文件本身）';        值=(Bytes $payloadTotal); 颜色='Yellow' }
  [pscustomobject]@{ 指标='逻辑大小（所有文件大小之和）';      值=(Bytes $logical);      颜色='Magenta' }
  [pscustomobject]@{ 指标='NTFS 实际占用';                   值='几乎不变（只多了 MFT 记录）'; 颜色='Green' }
  [pscustomobject]@{ 指标='逻辑 / 真实 放大倍数';             值=("{0:N0} 倍" -f $ratio); 颜色='Magenta' }
)
foreach ($r in $rows) { Write-Host ("  {0,-38} {1}" -f $r.指标, $r.值) -ForegroundColor $r.颜色 }
Write-Host ""
Write-Host ("  * 「逻辑大小」是备份/同步/配额工具默认看的指标 —— 它在这里虚高 {0:N0} 倍。" -f $ratio) -ForegroundColor Magenta

# ---------- git ----------
Head "阶段 C : 交给 git —— 这里才是真的爆炸"
Push-Location $Root
try {
  $null = & git init -q 2>&1
  $null = & git config user.email 'demo@local' 2>&1
  $null = & git config user.name 'demo' 2>&1
  $null = & git config core.autocrlf false 2>&1

  $sw2 = [Diagnostics.Stopwatch]::StartNew()
  Write-Host ("  git add .  （{0:N0} 个文件，请稍候）..." -f $ok) -ForegroundColor Yellow
  $null = & git add -A 2>&1
  $addSec = $sw2.Elapsed.TotalSeconds

  $sw3 = [Diagnostics.Stopwatch]::StartNew()
  $null = & git -c core.compression=0 commit -q -m 'flood' 2>&1
  $commitSec = $sw3.Elapsed.TotalSeconds

  $gitDir  = Join-Path $Root '.git'
  $gitSize = (Get-ChildItem -LiteralPath $gitDir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  $idxFile = Join-Path $gitDir 'index'
  $idxSize = if (Test-Path $idxFile) { (Get-Item $idxFile).Length } else { 0 }
  $counts = & git count-objects -v 2>$null

  Write-Host ""
  Write-Host ("    git add 耗时       : {0,10:N1} 秒" -f $addSec)
  Write-Host ("    git commit 耗时    : {0,10:N1} 秒" -f $commitSec)
  Write-Host ("    .git 总体积        : {0,12}" -f (Bytes $gitSize)) -ForegroundColor Yellow
  Write-Host ("    .git/index         : {0,12}   （每个文件一条记录）" -f (Bytes $idxSize))
  Write-Host ("    工作树真实数据     : {0,12}" -f (Bytes $payloadTotal))
  Write-Host ""
  Write-Host ("  * 放大倍数: {0:N0} 倍 —— {1} 的数据撑出了 {2} 的仓库。" -f ($gitSize/[Math]::Max($payloadTotal,1)), (Bytes $payloadTotal), (Bytes $gitSize)) -ForegroundColor Magenta
  Write-Host "    原因: git 的对象身份 =（内容 + 长度），与文件名无关；" -ForegroundColor DarkGray
  Write-Host "          但 tree 里每个路径各占一条记录，index 里每个文件各占一条。" -ForegroundColor DarkGray
  Write-Host "          「硬链接省空间」在 git 里完全失效 —— 它按路径逐个记账。" -ForegroundColor DarkGray
} finally {
  Pop-Location
}

# ---------- 删除代价 ----------
Head "阶段 D : 删除的代价"
$sw4 = [Diagnostics.Stopwatch]::StartNew()
if (-not $Keep) { Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue }
$left = Test-Path -LiteralPath $Root
Write-Host ("    删除 {0:N0} 个条目: {1:N1} 秒   残留: {2}" -f ($ok + $Sources), $sw4.Elapsed.TotalSeconds, $left) -ForegroundColor $(if ($left) { 'Red' } else { 'Green' })
if ($left) { Write-Host "    （git 的 .git/objects 里有大量只读文件，有时需要重试）" -ForegroundColor DarkYellow }

Head "结论"
Write-Host @"
  1. 磁盘占用 / 逻辑大小 / 文件个数 / git 体积 —— 四个指标可以互相差几个数量级。
     Break-This-Repo 把它推到极致：1.05 GiB、148,955 条目、45.2% 是 0 字节。

  2. 「0 字节文件」是最便宜的刷量方式：不占体积，只占文件数。
     而仓库首页只显示体积 —— 所以 67,369 个空文件在访客眼里不存在。

  3. 硬链接是更狠的版本：它连内容都能复用。
     NTFS 单文件上限是 1023 个链接（ERROR_TOO_MANY_LINKS = 1142），
     但多开几个载体文件就绕过去了 —— 8 KB 的数据可以是 10 万个文件。

  4. 任何只统计「工作树体积」的审查工具，都拦不住这三种手法。
"@ -ForegroundColor Gray
