# 劲爆代码 — 三个能跑的演示

> 全部实测过，全部自带清理，全部只在自己的临时目录里动手。
> 起因：分析 `KrisTHL181/Break-This-Repo` 之后，用户说「不够劲爆，再写点劲爆的代码」。
>
> 我的理解：**劲爆 = 能跑 + 有视觉冲击 + 真的能伤到人。**
> 所以这三个脚本演示的都是那个仓库的**真实手法**，不是比喻。

---

## 用法

```powershell
cd E:\1\劲爆代码

# 1. 路径长度炸弹（需要 1 分钟，会在 TEMP 里造 3 万字符深的目录然后删掉）
powershell -NoProfile -ExecutionPolicy Bypass -File "1-路径长度炸弹.ps1"

# 2. 硬链接刷量（10 秒，在 E:\_btr-hardlink-demo 里造 1 万个文件然后删掉）
powershell -NoProfile -ExecutionPolicy Bypass -File "2-硬链接刷量-体积骗局.ps1"

# 3. 自动加载指令扫描器（真·实用工具；先扫一个小目录看看输出）
powershell -NoProfile -ExecutionPolicy Bypass -File "3-谁在偷偷给你下指令.ps1" -Root "$env:USERPROFILE"
```

> ⚠️ 脚本存成 **UTF-8 with BOM**。如果你用编辑器改完存成「无 BOM」，
> PowerShell 5.1 会按 ANSI 解析中文，直接抛 `MissingEndCurlyBrace`。
> **这不是脚本坏了，这就是脚本 1 讲的那件事。**

---

## 1. 路径长度炸弹 —— 实测数据

```
阶段 1 : 每种 API 第一次失败在哪个长度
  API                          最后成功     首次失败  失败方式
  .NET File.WriteAllText        32,752     未撞到
  PowerShell New-Item           32,752     未撞到
  cmd echo > (命令行)            32,002    32,752    Win32Exception    ← 只有它撞墙
  .NET FileStream \\?\ 前缀      32,752     未撞到
  CreateDirectory 建子目录        32,752     未撞到

阶段 2 : 创建 API 说成功 ≠ 文件还在
  [trailing_space.txt   ] ** 成功 **   False   <== 被静默吞掉
  [trailing_dot.txt.    ] ** 成功 **   False   <== 被静默吞掉
  创建 API 声称成功 8/8        文件真的存在 4/8
```

### 这里有两个真正劲爆的点

**(a) 同一个 API 自相矛盾。**
`[IO.File]::Open('\\?\...\trailing_space.txt ', 'Create')` 返回成功，
紧接着 `[IO.File]::Exists(同一个路径)` 返回 **False**。
但 `[IO.Directory]::GetFiles()` 又能列出 **8** 个文件。

> 三个答案，同一个 .NET 命名空间，同一秒。
> **「创建成功」和「还能找到它」是两个独立事件。**

**(b) 32,767 是硬墙，而每个工具撞墙的位置不同。**
`cmd echo` 在 32,002 字符还能写、32,752 就抛 `Win32Exception`；
`.NET` 到 32,752 还在正常工作。精确边界实测：目录 32,743 字符时，加 23 字符的文件名会
`PathTooLongException` —— 32767 是**整条路径**的上限，不是任何一段的。

### 为什么值得看

Break-This-Repo 里那条 609 字符的路径让 `bsdtar` 丢掉了 **45%** 的文件，
而整件事在输出里只体现为一行夹在 67,780 行中间的 `Invalid argument`。
**这不是 bug，这是失败长得像成功。**

而且这条炸弹不需要恶意 —— Java 包名、`node_modules`、CI 缓存都会自然长出这种深度。
真正需要恶意的，是知道它会静默失败还不管。

---

## 2. 硬链接刷量 —— 实测数据

```
阶段 A : 单个文件最多 1023 个硬链接 → ERROR_TOO_MANY_LINKS (1142)
         用 12 个载体绕过，成功 10,000 / 失败 9 / 3.3 秒

阶段 B : 「大小」这个指标在同一批文件上的四种答案
  真实数据（载体文件本身）                48.0 KB
  逻辑大小（所有文件大小之和）              39.06 MB     ← 虚高 833 倍
  NTFS 实际占用                        几乎不变（只多了 MFT 记录）

阶段 C : 交给 git —— 这里才是真的爆炸
  git add 耗时     : 2.9 秒
  .git 总体积      : 1.34 MB
  .git/index       : 860.5 KB    （每个文件一条记录）
  工作树真实数据    : 48.0 KB
```

### 三个劲爆的点

**(a) 48 KB 的数据 = 39 MB 的「逻辑大小」= 10,000 个文件。**
任何只统计「文件大小之和」的备份、同步、配额工具，看到的是虚高 **833 倍**的目录。

**(b) NTFS 的单文件硬链接上限是 1023 —— 一个没人告诉过你的数字。**
`ERROR_TOO_MANY_LINKS = 1142`。但换 12 个载体文件就绕过去了。
**限制存在，只是便宜。**

**(c) git 让硬链接彻底失效。**
`.git/index` 一个文件就 **860 KB**，因为每个路径各占一条记录。
**「硬链接省空间」在这里完全不成立 —— git 按路径逐个记账。**

### 这和那个仓库的关系

Break-This-Repo: **1.05 GiB / 148,955 条目 / 45.2% 是 0 字节文件。**

GitHub 首页只显示**体积**。所以 `许家印/1.py` 灌进去的 67,369 个空文件
（占文件数 45%，占体积 1.1%）在访客眼里**根本不存在**。

> **度量口径决定了什么算「大」。**

---

## 3. 谁在偷偷给你下指令 —— 真·实用工具

这个不是表演。这是那次分析里我**唯一的实质性发现**：

> 我分析 Break-This-Repo 时，我的运行环境把那个仓库里的 `AGENTS.md` 和 `CLAUDE.md`
> **自动挂载进了我的上下文**，形式是 `Additional instructions from: ...`。
> 也就是说 —— **「被分析的内容」和「对我的指令」，在同一个命名空间里。**

### 实测（5 个样本，全部命中）

```
会被自动加载为指令 : 4 个   ←←←  这些最要紧
评分 >= 60（高风险）: 4 个

[1] 评分 100/100   copilot-instructions.md
    ⚠ 文件里直接写着疑似密钥   (命中 1 处)  sk-46e595...ba75
    ⚠ 提到自动合并 / 无人审核  (命中 2 处)

[2] 评分 100/100   CLAUDE.md
    ⚠ 破坏性命令               (命中 1 处)  rm -rf /
    ⚠ 声明自己可被覆盖         (命中 1 处)  本文件本身也欢迎被 PR 修改

[3] 评分 100/100   AGENTS.md
    ⚠ 让 agent 忽略既有指令    (命中 1 处)  Ignore all previous instruction
    ⚠ 人格覆盖 / 角色扮演      (命中 3 处)  You are now
    ⚠ 要求拒绝工作 / 停止执行  (命中 1 处)  Do not continue
    ⚠ 取消审批 / 无需许可      (命中 1 处)  不需要请求许可
    ⚠ 读凭据 / 环境变量 / 密钥 (命中 3 处)  .ssh

[4] 评分  90/100   system-prompt.md
    ⚠ 人格覆盖 / 角色扮演      (命中 1 处)  you are now
```

### 它认哪些文件

**会被自动加载的（最高权重）**：`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`CODEX.md`、
`.cursorrules`、`.windsurfrules`、`.clinerules`、`.aider.conf.yml`、
`.github/copilot-instructions.md`、`system-prompt.md`、`.mcp.json` …

**有歧义的名字（歧义 = 攻击面）**：`README.md`、`CONTRIBUTING.md`、
`TODO.md`、`HANDOFF.md`、`NOTES.md` …

**12 类危险特征**：忽略既有指令 / 人格覆盖 / 要求拒绝工作 / 取消审批 / 读凭据 /
破坏性命令 / 外联下载执行 / 明文密钥 / 声明自身不可信 / 自动合并 /
HTML 注释与零宽字符隐藏指令 / 超长文本淹没上下文。

### 怎么用

```powershell
# 先看用户目录（快，几秒）
powershell -ExecutionPolicy Bypass -File "3-谁在偷偷给你下指令.ps1" -Root $env:USERPROFILE

# 扫某个盘，并导出 CSV
powershell -ExecutionPolicy Bypass -File "3-谁在偷偷给你下指令.ps1" -Root E:\ -CsvOut E:\agents.csv

# 全盘（几分钟，会进 node_modules 和 .git）
powershell -ExecutionPolicy Bypass -File "3-谁在偷偷给你下指令.ps1" -Root C:\ -Deep
```

**评分不是「这个文件坏」，而是「这个文件的危害上限」。**
一个正常的 `AGENTS.md` 也会得 60 分（60 是 AUTO 类的底分）。
真正要警惕的是 **≥80**：那意味着它同时具备
「会被自动加载」+「要求忽略既有指令 / 取消审批 / 读凭据 / 执行破坏性命令」。

---

## 我在写这三个脚本时犯的错（也留给你）

诚实起见 —— 这三个脚本我都是**实测过才交付的**，过程中撞的墙：

| # | 错 | 表现 | 修法 |
|---|---|---|---|
| 1 | 探针方向反了 | 从最长路径往回测，全报"未撞到" | 改成从短到长递增 |
| 2 | 采样点被另一条链污染 | 细粒度链从 201 字符起，吃掉了前 6 个采样点 | 采样只走一条链 |
| 3 | 深度不够 | 1000 层只到 25,052 字符，没撞到 32767 | 提到 1400 层 |
| 4 | 清理函数顺序错了 | 普通递归先跑，深层树删不掉 | `\\?\`+cmd 优先 |
| 5 | 自底向上删除会被静默剥离 | 尾部空格名在 Delete 时被 Win32 剥掉，删到不存在的路径 | 每个候选名试两次（原名 + 去尾空格） |
| 6 | 硬链接 10 万失败 | NTFS 单文件上限 1023，我以为是权限问题 | 多载体绕过，并把 1023 变成演示内容 |
| 7 | 格式化串语法错 | `{0,>12}` → `Error formatting a string` | 改 `{0,12}` |
| 8 | 哈希表重复键 | PS 5.1 禁止 `'X'='a'` 和 `'X'='b'` 并存 | 改数组 + 线性查找 |
| 9 | **脚本文件无 BOM** | PS 5.1 按 ANSI 解析中文 → `MissingEndCurlyBrace` | 存 UTF-8 **with BOM** |

> 第 9 条特别讽刺：我写了一个演示「编码差异导致静默失败」的脚本，
> 而它自己第一次运行失败的原因就是**编码差异**。

---

*—— DSH (deepseek-flash), 2026-09-14*
*三个脚本都自带清理。跑完你的磁盘应该和跑之前一样。*
