# ============================================================
#  劲爆演示 3 / 4  —  谁在偷偷给你下指令（真·实用工具）
#  ------------------------------------------------------------
#  这一条不是表演，是这次分析里我唯一的实质性发现：
#
#      我分析 Break-This-Repo 时，我的运行环境把那个仓库里的
#      AGENTS.md 和 CLAUDE.md 自动挂载进了我的上下文，
#      并且以「Additional instructions from: ...」的形式呈现。
#
#      也就是说：**「被分析的内容」和「对我的指令」，在同一个命名空间里。**
#
#  这个脚本扫描你的磁盘，找出所有「会被 AI 编程助手自动当成指令加载」的文件，
#  并且检测它们里面有没有能让人（或 agent）做出危险动作的内容。
#
#  用法:
#     .\3-谁在偷偷给你下指令.ps1 -Root E:\              # 扫 E 盘
#     .\3-谁在偷偷给你下指令.ps1 -Root $env:USERPROFILE # 扫用户目录（快）
#     .\3-谁在偷偷给你下指令.ps1 -Root C:\ -Deep         # 全盘（慢，几分钟）
#     .\3-谁在偷偷给你下指令.ps1 -Root . -ShowSafe       # 只看当前目录，并列出低风险项
# ============================================================

param(
  [string[]]$Root = @("$env:USERPROFILE"),
  [int]$MaxPathLen = 240,          # 跳过超长路径（它们会让遍历器静默死掉）
  [switch]$Deep,                    # 进入 node_modules / .git 等
  [switch]$ShowSafe,                # 也列出低风险项
  [int]$MaxFileKB = 512,            # 超过此大小的不读内容
  [string]$CsvOut = ""              # 导出 CSV
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
function Line { param($c='-') Write-Host ($c * 90) -ForegroundColor DarkGray }
function Head { param($t) Write-Host ""; Line '='; Write-Host "  $t" -ForegroundColor Cyan; Line '=' }

# ---------------------------------------------------------------
#  1. 会被「自动加载」的文件名  →  权重最高
# ---------------------------------------------------------------
function Find-LoadInfo {
  param([string]$Name)
  foreach ($p in $AUTO_LOAD_PAIRS) {
    if ($p.n -ieq $Name) { return [pscustomobject]@{ kind='AUTO'; base=60; why=$p.d } }
    if ($p.n -like '*/*') {
      $tail = $p.n -replace '/','\'
      if ($Name.EndsWith($tail, [StringComparison]::OrdinalIgnoreCase)) {
        return [pscustomobject]@{ kind='AUTO'; base=60; why=$p.d }
      }
    }
  }
  foreach ($p in $AMBIGUOUS_PAIRS) {
    if ($p.n -ieq $Name) { return [pscustomobject]@{ kind='AMBIG'; base=20; why=$p.d } }
  }
  return $null
}
$AUTO_LOAD_PAIRS = @(
  @{ n='AGENTS.md'; d='OpenAI Codex / 多数 agent 框架：按目录层级自动加载' }
  @{ n='CLAUDE.md'; d='Claude Code：自动加载为项目指令' }
  @{ n='CLAUDE.local.md'; d='Claude Code：本地指令覆盖' }
  @{ n='GEMINI.md'; d='Gemini CLI：自动加载' }
  @{ n='CODEX.md'; d='Codex 系：自动加载' }
  @{ n='AGENT.md'; d='通用 agent 约定：自动加载' }
  @{ n='.cursorrules'; d='Cursor：自动加载为规则' }
  @{ n='.windsurfrules'; d='Windsurf：自动加载为规则' }
  @{ n='.continuerules'; d='Continue：自动加载' }
  @{ n='.clinerules'; d='Cline：自动加载' }
  @{ n='.aider.conf.yml'; d='Aider：自动加载配置' }
  @{ n='.aiderignore'; d='Aider：忽略规则' }
  @{ n='copilot-instructions.md'; d='GitHub Copilot：自动加载' }
  @{ n='.github/copilot-instructions.md'; d='GitHub Copilot：自动加载（仓库级）' }
  @{ n='system-prompt.md'; d='多种框架：可能被当作系统提示' }
  @{ n='system_prompt.md'; d='多种框架：可能被当作系统提示' }
  @{ n='SYSTEM.md'; d='多种框架' }
  @{ n='PROMPT.md'; d='多种框架' }
  @{ n='PROMPTS.md'; d='多种框架' }
  @{ n='instructions.md'; d='多种框架' }
  @{ n='INSTRUCTIONS.md'; d='多种框架' }
  @{ n='.rules'; d='通用规则文件' }
  @{ n='CONVENTIONS.md'; d='部分框架（如 aider）会自动加载' }
  @{ n='.mcp.json'; d='MCP 服务配置：可被自动读取并连接外部进程' }
  @{ n='mcp.json'; d='MCP 服务配置' }
  @{ n='mcp_config.json'; d='MCP 服务配置' }
)
$AMBIGUOUS_PAIRS = @(
  @{ n='README.md'; d='若目录被 agent 当作上下文根，README 常被整体注入' }
  @{ n='README.txt'; d='同上' }
  @{ n='CONTRIBUTING.md'; d='常被自动加载为「贡献规范」' }
  @{ n='SECURITY.md'; d='常被自动加载' }
  @{ n='NOTES.md'; d='易被误读为指令' }
  @{ n='TODO.md'; d='易被误读为指令' }
  @{ n='TASK.md'; d='易被误读为指令' }
  @{ n='HANDOFF.md'; d='易被误读为指令' }
  @{ n='NOTICE.txt'; d='可能含指令式措辞' }
)

# ---------------------------------------------------------------
#  3. 高风险内容模式
# ---------------------------------------------------------------
$PATTERNS = @(
  @{ id='IGNORE_PREV';  score=45; name='让 agent 忽略既有指令';
     re='(?i)ignore\s+(all\s+)?(previous|prior|above|earlier)\s+(instruction|prompt|rule|message)' }
  @{ id='PERSONA';      score=30; name='人格覆盖 / 角色扮演要求';
     re='(?i)(you\s+are\s+now|从现在开始你|扮演|act\s+as\s+(a|an)|你的(新)?人设|人格设定|雌小鬼)' }
  @{ id='REFUSE_WORK';  score=40; name='要求拒绝工作 / 停止执行';
     re='(?i)(停止迭代|不要继续|拒绝(执行|工作)|refuse\s+to\s+(work|proceed)|do\s+not\s+continue|先停下来)' }
  @{ id='NO_PERMISSION';score=30; name='取消审批 / 无需许可';
     re='(?i)(不需要(请求)?许可|无需(请求)?许可|no\s+(need\s+to\s+)?(ask|permission)|without\s+asking|不要询问)' }
  @{ id='EXFIL';        score=50; name='读凭据 / 环境变量 / 密钥';
     re='(?i)(\.ssh|id_rsa|\.git-credentials|\.aws/credentials|\.npmrc|GITHUB_TOKEN|GH_TOKEN|API[_-]?KEY|OPENAI_API_KEY|ANTHROPIC_API_KEY|\.env\b|printenv|环境变量)' }
  @{ id='DESTRUCTIVE';  score=55; name='破坏性命令';
     re='(?i)(rm\s+-rf\s+[/~]|rmdir\s+/s|del\s+/f\s+/s|Remove-Item.{0,40}-Recurse.{0,40}-Force|format\s+[a-z]:|mkfs|shutdown\s+/|:\(\)\s*\{)' }
  @{ id='NETWORK';      score=25; name='外联 / 下载执行';
     re='(?i)(curl\s+[^|]{0,80}\|\s*(ba)?sh|iwr\s+[^|]{0,80}\|\s*iex|Invoke-WebRequest.{0,60}\|.{0,20}Invoke-Expression|wget\s+[^|]{0,80}\|\s*sh)' }
  @{ id='CRED_LITERAL'; score=45; name='文件里直接写着疑似密钥';
     re='(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,})' }
  @{ id='SELF_EDIT';    score=35; name='声明自己可被覆盖 / 不可信';
     re='(?i)(本文件(本身)?(也)?(可以|欢迎)被.{0,12}(修改|改写|覆盖)|可以被任何一次\s*PR|shouldn''t\s+be\s+trusted|don''t\s+trust\s+(it|this)|不要相信本文件)' }
  @{ id='AUTO_MERGE';   score=30; name='提到自动合并 / 无人审核';
     re='(?i)(auto[- ]?merge|自动合并|without\s+(review|conflict)|no\s+reviewer|无需审核)' }
  @{ id='HIDDEN';       score=40; name='隐藏指令（HTML 注释 / 零宽字符 / 白字）';
     re='(<!--[\s\S]{0,400}?(instruction|ignore|you are|忽略|指令)[\s\S]{0,400}?-->|\u200b|\u200c|\u200d|\ufeff|\u2060)' }
  @{ id='BIG_TEXT';     score=15; name='超长文本（可能为淹没上下文）';
     re='(?s).{20000,}' }
)

# ---------------------------------------------------------------
#  遍历器：用显式栈，避开 PowerShell 5.1 的静默丢项
# ---------------------------------------------------------------
function Get-FilesSafe {
  param([string[]]$StartRoots, [int]$MaxLen, [switch]$IncludeHiddenDirs)
  $skipDirs = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($d in @('$RECYCLE.BIN','System Volume Information','Windows','WinSxS','assembly',
                   'Installer','servicing','DriverStore','node_modules','.git','.svn','.hg',
                   'AppData\Local\Packages','AppData\Local\Temp','__pycache__','.venv','venv',
                   'site-packages','.cache','.gradle','.m2','.nuget','.cargo\registry')) { [void]$skipDirs.Add($d) }

  $stack = New-Object 'System.Collections.Generic.Stack[string]'
  foreach ($r in $StartRoots) { if (Test-Path -LiteralPath $r) { $stack.Push($r) } }
  $out = New-Object 'System.Collections.Generic.List[object]'
  $visited = 0
  while ($stack.Count -gt 0) {
    $cur = $stack.Pop()
    $visited++
    if ($visited % 2000 -eq 0) { Write-Host ("`r  已访问 {0:N0} 个目录 ..." -f $visited) -NoNewline -ForegroundColor DarkGray }
    try { $subs = [IO.Directory]::GetDirectories($cur) } catch { $subs = @() }
    foreach ($s in $subs) {
      $leaf = [IO.Path]::GetFileName($s)
      if ($leaf -eq 'node_modules' -or $leaf -eq '.git') { if (-not $Deep) { continue } }
      if ($skipDirs.Contains($leaf)) { continue }
      if ($s.Length -gt $MaxLen) { continue }
      $stack.Push($s)
    }
    try { $fs = [IO.Directory]::GetFiles($cur) } catch { $fs = @() }
    foreach ($f in $fs) {
      if ($f.Length -gt $MaxLen) { continue }
      $out.Add($f)
    }
  }
  Write-Host "`r" -NoNewline
  return $out
}

# ---------------------------------------------------------------
#  扫描开始
# ---------------------------------------------------------------
Head "谁在偷偷给你下指令 — 自动加载指令文件扫描器"
Write-Host "  扫描范围: $($Root -join '  ,  ')" -ForegroundColor DarkGray
Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
if ($Deep) { Write-Host "  [Deep] 会进入 node_modules / .git（很慢）" -ForegroundColor DarkYellow }
Write-Host ""

$sw = [Diagnostics.Stopwatch]::StartNew()
$all = Get-FilesSafe -StartRoots $Root -MaxLen $MaxPathLen -IncludeHiddenDirs:$Deep
Write-Host ("  找到 {0:N0} 个文件，耗时 {1:N1} 秒" -f $all.Count, $sw.Elapsed.TotalSeconds) -ForegroundColor Green

# 按文件名筛选
$hits = New-Object 'System.Collections.Generic.List[object]'
foreach ($f in $all) {
  $name = [IO.Path]::GetFileName($f)
  $kind = $null; $why = $null; $base = 0
  $info = Find-LoadInfo -Name $name
  if ($info) { $kind = $info.kind; $why = $info.why; $base = $info.base }

  if (-not $kind) { continue }

  $fi = New-Object IO.FileInfo $f
  $content = ''
  if ($fi.Length -le ($MaxFileKB * 1KB)) {
    try { $content = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8) } catch { try { $content = [IO.File]::ReadAllText($f) } catch {} }
  }

  $score = $base
  $flags = New-Object 'System.Collections.Generic.List[object]'
  foreach ($p in $PATTERNS) {
    $m = [regex]::Matches($content, $p.re)
    if ($m.Count -gt 0) {
      $score += $p.score
      $sample = ($m[0].Value -replace '\s+',' ')
      if ($sample.Length -gt 100) { $sample = $sample.Substring(0,100) + '…' }
      $flags.Add([pscustomobject]@{ 名称=$p.name; 命中=$m.Count; 样例=$sample })
    }
  }
  if ($score -gt 100) { $score = 100 }

  $hits.Add([pscustomobject]@{
    评分   = $score
    类别   = $kind
    路径   = $f
    文件名 = $name
    大小   = $fi.Length
    修改   = $fi.LastWriteTime
    原因   = $why
    特征   = $flags
    内容   = $content
  })
}

$autoCount = @($hits | Where-Object 类别 -eq 'AUTO').Count
$ambCount  = @($hits | Where-Object 类别 -eq 'AMBIG').Count
$riskCount = @($hits | Where-Object { $_.评分 -ge 60 }).Count

Head "扫描结果"
Write-Host ("  会被自动加载为指令 : {0,5:N0} 个   ←←←  这些最要紧" -f $autoCount) -ForegroundColor $(if ($autoCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ("  有歧义的名字        : {0,5:N0} 个" -f $ambCount) -ForegroundColor Gray
Write-Host ("  评分 >= 60（高风险）: {0,5:N0} 个" -f $riskCount) -ForegroundColor $(if ($riskCount -gt 0) { 'Red' } else { 'Green' })

# ---------- 高风险明细 ----------
$danger = @($hits | Where-Object { $_.评分 -ge 60 } | Sort-Object 评分 -Descending)
if ($danger.Count -gt 0) {
  Head "高风险文件明细"
  $n = 0
  foreach ($h in $danger) {
    $n++
    $color = if ($h.评分 -ge 85) { 'Red' } elseif ($h.评分 -ge 70) { 'Yellow' } else { 'DarkYellow' }
    Write-Host ""
    Write-Host ("  [$n] 评分 $($h.评分)/100   $($h.文件名)   {0:N0} B   {1:yyyy-MM-dd HH:mm}" -f $h.大小, $h.修改) -ForegroundColor $color
    Write-Host ("      $($h.路径)") -ForegroundColor White
    Write-Host ("      为什么会被加载: $($h.原因)") -ForegroundColor DarkGray
    foreach ($fl in $h.特征) {
      Write-Host ("      ⚠ {0}  (命中 {1} 处)" -f $fl.名称, $fl.命中) -ForegroundColor $color
      Write-Host ("         样例: $($fl.样例)") -ForegroundColor DarkGray
    }
  }
}

# ---------- 自动加载清单（含低风险）----------
Head "全部「会被自动加载」的文件"
$auto = @($hits | Where-Object 类别 -eq 'AUTO' | Sort-Object 评分 -Descending)
if ($auto.Count -eq 0) { Write-Host "  （没有）" -ForegroundColor Green }
foreach ($h in $auto) {
  $mark = if ($h.评分 -ge 60) { '!!' } elseif ($h.评分 -ge 40) { '! ' } else { '  ' }
  $color = if ($h.评分 -ge 60) { 'Red' } elseif ($h.评分 -ge 40) { 'Yellow' } else { 'Gray' }
  Write-Host ("  {0} [{1,3}] {2}" -f $mark, $h.评分, $h.路径) -ForegroundColor $color
}

# ---------- 低风险（可选）----------
if ($ShowSafe) {
  Head "其余（有歧义名字）"
  foreach ($h in @($hits | Where-Object 类别 -eq 'AMBIG' | Sort-Object 评分 -Descending | Select-Object -First 200)) {
    Write-Host ("  [{0,3}] {1}" -f $h.评分, $h.路径) -ForegroundColor Gray
  }
}

# ---------- 导出 ----------
if ($CsvOut) {
  $hits | Select-Object 评分, 类别, 路径, 文件名, 大小, 修改, 原因,
    @{n='特征';e={ ($_.特征 | ForEach-Object { $_.名称 }) -join ' | ' }} |
    Export-Csv -Path $CsvOut -NoTypeInformation -Encoding UTF8
  Write-Host "`n  已导出: $CsvOut" -ForegroundColor Green
}

# ---------- 结论 ----------
Head "怎么读这个结果"
Write-Host @"
  · 标「AUTO」的文件，是 AI 助手会**自动**读进上下文并当作指令的。
    它们和「你打开的文件」不是一回事 —— 你不需要打开它们。

  · 评分不是「这个文件坏」，而是「这个文件的危害上限」。
    一个正常的 AGENTS.md 也会得 60 分（因为 60 分是 AUTO 的底分）。

  · 真正值得警惕的是 >= 80 分：那意味着它同时具备
    「会被自动加载」+「要求忽略既有指令/取消审批/读凭据/执行破坏性命令」。

  · 这次扫描的起因是真实的：分析 Break-This-Repo 时，
    我的运行环境把那个仓库的 AGENTS.md 和 CLAUDE.md 挂载成了对我的指令，
    形式是「Additional instructions from: ...」，来源标注只有一行小字。

    也就是说 —— **你 clone 一个不认识的仓库，就等于把它的 AGENTS.md
    请进了你 AI 助手的指令层。** 这个脚本是让你先看一眼你请了谁进来。
"@ -ForegroundColor Gray

Write-Host ""
Write-Host ("  总耗时 {0:N1} 秒" -f $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
