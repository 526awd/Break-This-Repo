# Translations / 多语言 README

本目录收录 [`README.markdown`](../README.markdown)（原 `README.md`）的多语言译文。

## 文件命名

```
translations/README.<ISO 639-1 代码>.md
```

代码即该语言的 ISO 639-1 二字码（同时是合法的 BCP 47 主语言标签），
例如 `README.ja.md`（日语）、`README.de.md`（德语）、`README.ar.md`（阿拉伯语）。
完整语言清单见 [`_tools/languages.json`](./_tools/languages.json)（共 184 种）。

## 当前进度

**52 / 184**。欢迎继续补充，每个语种一个文件，互不冲突。

## 一致性约定

184 个译文如果各译各的，锚点和结构会很快走样。因此约定如下：

1. **逐行对应**：章节数、代码块数量、空行位置与源文档**逐行一致**。
   校验器用「结构指纹」（每行是标题/空行/正文/围栏的分类序列）逐行比对，而不是只比行数——
   行数相同但空行错位会导致整段错位，只有指纹能发现。
2. **不翻译**：代码块内容、Shell 命令与参数、URL、文件路径、相对链接、
   `alt="image"`、专有名词（CMake / maturin / Debian / OpenJDK 等）、
   以及含中文的两处相对路径（`./留言与聊天/…`、`./OneShotWME壁纸/…`）。
3. **要翻译**：所有标题（含英文标题）、正文、引用块、图片 `title`、
   TOC 条目、以及代码块里的自然语言注释。
4. **TOC 锚点用脚本重建，不要手算**。
   源文档自带的 TOC 里有 3 条失效锚点（它由编辑器插件生成，与 GitHub 规则并不一致），
   本项目不复制这个缺陷。

## 工具（`_tools/`）

无依赖，只需 Node.js：

```bash
node _tools/validate.mjs            # 校验全部译文，必须全绿
node _tools/validate.mjs ja de      # 只校验指定语种
node _tools/toc.mjs                 # 锚点算法 6 项自检
node _tools/toc.mjs rebuild ja      # 按 GitHub 真实规则重建某译文的 TOC
node _tools/audit-headings.mjs      # 列出各语种还没翻译的标题
node _tools/struct-diff.mjs ja      # 打印某译文相对源文档的结构差异段
node _tools/progress-check.mjs      # 独立复算进度与关键不变量
node _tools/gen-index.mjs           # 重新生成本文件下方的索引
```

`_tools/upstream-README.md` 是翻译所用的**源文档快照**（462 行），
保留它是为了让校验器有一个稳定的比对基准。

## 收录的语种

<!-- 本段由 _tools/gen-index.mjs 生成 -->

`aa` `ab` `ae` `af` `an` `ar` `av` `bh` `bs` `ca` `ch` `co` `cs` `da` `de` `el` `en` `es`
`et` `fi` `fo` `fr` `fy` `gl` `he` `hi` `hr` `hu` `is` `it` `ja` `ko` `lb` `lt` `lv` `mk`
`nb` `nl` `nn` `no` `oc` `pl` `pt` `rm` `ru` `sk` `sl` `sr` `sv` `th` `tr` `uk`

## 说明

- 译文由 AI 批量生成并经过上述自动化结构校验。**结构合格不等于语言完美**，
  小语种与长段落建议以源文档为准；欢迎母语者直接提 PR 修正措辞。
- 源文档仍在频繁变动（本仓库会自动合并 PR）。这 52 份对应的是
  `_tools/upstream-README.md` 那份快照；源文档后续新增的章节尚未覆盖，欢迎增量补齐。
