#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"


python3 "$ROOT/.agents/flavor/bfs_miaomiao.py"
python3 "$ROOT/.agents/flavor/scan_larger_than.py -s 50 -y"

echo "自助清理服务已执行: 五十MB以上者，死刑立即执行！"