import { buildSnapshot, formatMarkdown, parseCommitLog } from "./repo-observatory.ts";

Deno.test("parses text and binary numstat entries", () => {
  const nul = String.fromCharCode(0);
  const commits = parseCommitLog([
    `0123456789abcdef0123456789abcdef01234567${nul}Alice${nul}2026-09-01T00:00:00+08:00${nul}`,
    `\n3\t1\tREADME.md${nul}`,
    `-\t-\tcat.jpeg${nul}`,
    `\nfedcba9876543210fedcba9876543210fedcba98${nul}Bob${nul}2026-08-31T00:00:00+08:00${nul}`,
    `\n2\t0\ttools/report.ts${nul}`,
  ].join(""));
  if (commits.length !== 2 || commits[0].additions !== 3 || commits[0].deletions !== 1) {
    throw new Error("numstat was parsed incorrectly");
  }
  if (commits[0].files.length !== 2) throw new Error("binary file was dropped");
});

Deno.test("builds stable aggregate rankings", () => {
  const nul = String.fromCharCode(0);
  const snapshot = buildSnapshot(parseCommitLog(`0123456789abcdef0123456789abcdef01234567${nul}A${nul}2026-01-01T00:00:00Z${nul}\n1\t2\ta.ts${nul}`), ["a.ts", "README"]);
  if (snapshot.additions !== 1 || snapshot.deletions !== 2) throw new Error("totals are wrong");
  if (snapshot.extensions[0].extension !== ".ts") throw new Error("extension ranking is wrong");
  if (!formatMarkdown(snapshot).includes("# 仓库观测报告")) throw new Error("markdown is incomplete");
});

Deno.test("does not let unusual names break the markdown table", () => {
  const report = formatMarkdown(buildSnapshot([
    {
      hash: "0123456789abcdef0123456789abcdef01234567",
      author: "A|B\n<script>",
      date: "2026-01-01T00:00:00Z",
      additions: 0,
      deletions: 0,
      files: ["odd|name`\n.md"],
    },
  ], ["odd|name`.md"]));
  if (report.includes("<script>") || report.includes("odd|name`\n")) {
    throw new Error("untrusted names were not escaped");
  }
});
