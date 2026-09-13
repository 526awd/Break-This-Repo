export interface CommitStat {
  hash: string;
  author: string;
  date: string;
  additions: number;
  deletions: number;
  files: string[];
}

export interface RepositorySnapshot {
  commits: number;
  contributors: number;
  files: number;
  additions: number;
  deletions: number;
  latestCommitAt: string | null;
  authors: { name: string; commits: number }[];
  extensions: { extension: string; files: number }[];
  mostChanged: { path: string; changes: number }[];
}

/** Parse `git log --numstat` output without trusting file contents as shell input. */
export function parseCommitLog(log: string): CommitStat[] {
  const commits: CommitStat[] = [];
  let current: CommitStat | null = null;

  const addChange = (line: string) => {
    if (!current) return;
    const change = line.split("\t");
    if (change.length < 3) return;
    const additions = Number.parseInt(change[0], 10);
    const deletions = Number.parseInt(change[1], 10);
    current.additions += Number.isFinite(additions) ? additions : 0;
    current.deletions += Number.isFinite(deletions) ? deletions : 0;
    current.files.push(change.slice(2).join("\t"));
  };

  // `git log -z` keeps author names and paths intact even when they contain newlines.
  if (log.includes("\0")) {
    const records = log.split("\0");
    for (let index = 0; index < records.length; index++) {
      const line = records[index].replace(/^\n/, "");
      if (
        /^[0-9a-f]{40}$/i.test(line) &&
        /^\d{4}-\d{2}-\d{2}T/.test(records[index + 2] ?? "")
      ) {
        current = {
          hash: line,
          author: records[index + 1],
          date: records[index + 2],
          additions: 0,
          deletions: 0,
          files: [],
        };
        commits.push(current);
        index += 2;
        continue;
      }
      if (line.trim()) addChange(line);
    }
    return commits;
  }

  // Keep accepting the tab-separated format for callers with saved old reports.
  for (const rawRecord of log.split(/\r?\n/)) {
    const line = rawRecord.replace(/^\n/, "");
    if (!line.trim()) continue;
    const metadata = line.split("\t");
    if (
      metadata.length === 3 &&
      /^[0-9a-f]{40}$/i.test(metadata[0]) &&
      /^\d{4}-\d{2}-\d{2}T/.test(metadata[2])
    ) {
      current = {
        hash: metadata[0],
        author: metadata[1],
        date: metadata[2],
        additions: 0,
        deletions: 0,
        files: [],
      };
      commits.push(current);
      continue;
    }
    addChange(line);
  }
  return commits;
}

function extensionOf(path: string): string {
  const name = path.split("/").pop() ?? path;
  const dot = name.lastIndexOf(".");
  return dot > 0 ? name.slice(dot).toLowerCase() : "(无扩展名)";
}

function escapeMarkdownCell(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("|", "\\|")
    .replaceAll("`", "\\`")
    .replaceAll(/\r?\n/g, " ");
}

export function buildSnapshot(commits: CommitStat[], files: string[]): RepositorySnapshot {
  const authorCounts = new Map<string, number>();
  const extensionCounts = new Map<string, number>();
  const changedCounts = new Map<string, number>();
  let additions = 0;
  let deletions = 0;

  for (const commit of commits) {
    authorCounts.set(commit.author, (authorCounts.get(commit.author) ?? 0) + 1);
    additions += commit.additions;
    deletions += commit.deletions;
    for (const path of commit.files) {
      changedCounts.set(path, (changedCounts.get(path) ?? 0) + 1);
    }
  }
  for (const path of files) {
    const extension = extensionOf(path);
    extensionCounts.set(extension, (extensionCounts.get(extension) ?? 0) + 1);
  }

  const byCount = (left: [string, number], right: [string, number]) =>
    right[1] - left[1] || left[0].localeCompare(right[0]);
  return {
    commits: commits.length,
    contributors: authorCounts.size,
    files: files.length,
    additions,
    deletions,
    latestCommitAt: commits[0]?.date ?? null,
    authors: [...authorCounts].sort(byCount).map(([name, count]) => ({ name, commits: count })),
    extensions: [...extensionCounts].sort(byCount).map(([extension, count]) => ({ extension, files: count })),
    mostChanged: [...changedCounts]
      .sort(byCount)
      .slice(0, 10)
      .map(([path, changes]) => ({ path, changes })),
  };
}

function runGit(repo: string, args: string[]): string {
  const command = new Deno.Command("git", {
    args: ["-C", repo, ...args],
    stdout: "piped",
    stderr: "piped",
  });
  const result = command.outputSync();
  if (!result.success) {
    throw new Error(new TextDecoder().decode(result.stderr).trim() || "git 命令执行失败");
  }
  return new TextDecoder().decode(result.stdout);
}

export function formatMarkdown(snapshot: RepositorySnapshot): string {
  const lines = [
    "# 仓库观测报告",
    "",
    "> 由 `tools/repo-observatory.ts` 根据当前 Git 历史生成。它描述变化，不评价内容。",
    "",
    `快照提交：${snapshot.latestCommitAt ?? "暂无提交"}`,
    "",
    "## 总览",
    "",
    "| 指标 | 数值 |",
    "| --- | ---: |",
    `| 提交数 | ${snapshot.commits} |`,
    `| 参与者 | ${snapshot.contributors} |`,
    `| 当前文件数 | ${snapshot.files} |`,
    `| 新增行数 | ${snapshot.additions} |`,
    `| 删除行数 | ${snapshot.deletions} |`,
    "",
    "## 参与者",
    "",
    "| 名称 | 提交数 |",
    "| --- | ---: |",
    ...snapshot.authors.map(({ name, commits }) => `| ${escapeMarkdownCell(name)} | ${commits} |`),
    "",
    "## 文件类型",
    "",
    "| 扩展名 | 文件数 |",
    "| --- | ---: |",
    ...snapshot.extensions.map(({ extension, files }) => `| \`${escapeMarkdownCell(extension)}\` | ${files} |`),
    "",
    "## 最常被改动的文件",
    "",
    "| 路径 | 涉及提交数 |",
    "| --- | ---: |",
    ...snapshot.mostChanged.map(({ path, changes }) => `| \`${escapeMarkdownCell(path)}\` | ${changes} |`),
    "",
  ];
  return lines.join("\n");
}

function usage(message?: string): never {
  if (message) console.error(`参数错误：${message}`);
  console.error("用法：deno run --allow-read --allow-run tools/repo-observatory.ts [--repo PATH] [--json]");
  Deno.exit(1);
}

if (import.meta.main) {
  const args = [...Deno.args];
  let repo = ".";
  let json = false;
  for (let index = 0; index < args.length; index++) {
    switch (args[index]) {
      case "--repo":
        if (!args[index + 1] || args[index + 1].startsWith("--")) {
          usage("--repo 后必须提供目录路径");
        }
        repo = args[++index];
        break;
      case "--json":
        json = true;
        break;
      case "--help":
        usage();
      default:
        usage(`未知参数：${args[index]}`);
    }
  }

  // rev-parse distinguishes an empty repository from an invalid repository.
  runGit(repo, ["rev-parse", "--is-inside-work-tree"]);
  let commits: CommitStat[] = [];
  let hasHead = true;
  try {
    runGit(repo, ["rev-parse", "--verify", "HEAD"]);
  } catch {
    // A valid repository may not have its first commit yet.
    hasHead = false;
  }
  if (hasHead) {
    commits = parseCommitLog(runGit(repo, ["log", "-z", "--no-renames", "--format=%H%x00%an%x00%aI%x00", "--numstat"]));
  }
  const files = runGit(repo, ["ls-files", "-z"]).split("\0").filter(Boolean);
  const snapshot = buildSnapshot(commits, files);
  if (json) {
    console.log(JSON.stringify(snapshot, null, 2));
  } else {
    console.log(formatMarkdown(snapshot));
  }
}
