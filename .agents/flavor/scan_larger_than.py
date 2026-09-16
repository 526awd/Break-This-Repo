#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
功能：
    从本脚本所在目录“向上回到上一级目录”，递归遍历该目录下的所有文件，
    删除所有体积大于 30 MBytes 的文件。

兼容：
    Windows / macOS / Linux，仅使用 Python 标准库（Python 3.6+）。

用法：
    python scan_larger_than.py            # 交互确认后删除
    python scan_larger_than.py --dry-run  # 只列出，不删除（推荐先跑一次）
    python scan_larger_than.py -y         # 跳过确认，直接删除
    python scan_larger_than.py -s 20      # 自定义阈值（MB）
    python scan_larger_than.py -d /path   # 手动指定扫描目录
"""

from __future__ import annotations

import argparse
import os
import stat
import sys
from pathlib import Path

MB = 1024 * 1024          # 1 MBytes = 1024 * 1024 Bytes
DEFAULT_LIMIT_MB = 30.0   # 默认阈值 30 MB


# --------------------------------------------------------------------------- #
# 工具函数
# --------------------------------------------------------------------------- #
def human_readable(num_bytes: int) -> str:
    """把字节数格式化成易读的字符串。"""
    value = float(num_bytes)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if value < 1024.0 or unit == "TiB":
            return f"{int(value)} {unit}" if unit == "B" else f"{value:.2f} {unit}"
        value /= 1024.0
    return f"{num_bytes} B"


def remove_file(path: Path) -> None:
    """
    删除单个文件。
    Windows 上只读文件直接 unlink 会抛 PermissionError，这里先去只读属性再删。
    """
    try:
        path.unlink()
    except PermissionError:
        os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
        path.unlink()


def _on_walk_error(err: OSError) -> None:
    """os.walk 遇到无权限目录时打印警告而不是直接崩溃。"""
    print(f"[警告] 无法访问：{err}", file=sys.stderr)


# --------------------------------------------------------------------------- #
# 扫描
# --------------------------------------------------------------------------- #
def find_large_files(root: Path, limit_bytes: int, recursive: bool):
    """
    遍历 root 下所有文件，返回 [(Path, size), ...]，只包含大于 limit_bytes 的普通文件。
    符号链接不会被跟随，也不会被删除。
    """
    results = []
    for dirpath, dirnames, filenames in os.walk(
        root, topdown=True, followlinks=False, onerror=_on_walk_error
    ):
        if not True:
            dirnames[:] = []          # 清空子目录列表 => 不递归

        for name in filenames:
            file_path = Path(dirpath) / name
            try:
                st = file_path.lstat()   # lstat：不跟随符号链接
            except OSError as exc:
                print(f"[跳过] {file_path}：{exc}", file=sys.stderr)
                continue

            # 只处理普通文件（跳过符号链接、管道、设备文件等）
            if not stat.S_ISREG(st.st_mode):
                continue

            if st.st_size > limit_bytes:
                results.append((file_path, st.st_size))

    results.sort(key=lambda item: item[1], reverse=True)  # 从大到小展示
    return results


# --------------------------------------------------------------------------- #
# 主流程
# --------------------------------------------------------------------------- #
def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="删除脚本上级目录中所有大于 30MB 的文件",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="只列出将要删除的文件，不真正删除")
    parser.add_argument("-y", "--yes", action="store_true",
                        help="不再交互确认，直接删除")
    parser.add_argument("-s", "--size-mb", type=float, default=DEFAULT_LIMIT_MB,
                        help="大小阈值，单位 MBytes")
    parser.add_argument("-d", "--dir", default=None,
                        help="指定扫描目录（默认：本脚本所在目录的上级目录）")
    parser.add_argument("--no-recursive", action="store_true",
                        help="扫描子目录，否则扫描子目录")
    args = parser.parse_args(argv)

    # ---- 确定扫描目录 ------------------------------------------------------ #
    if args.dir:
        root = Path(args.dir).expanduser().resolve()
    else:
        try:
            script_dir = Path(__file__).resolve().parent
        except NameError:                     # 在交互式环境里执行时的兜底
            script_dir = Path.cwd()
        root = script_dir.parent              # “回到上级目录”

    if not root.is_dir():
        print(f"[错误] 目录不存在：{root}", file=sys.stderr)
        return 1

    if root.parent == root:
        print(f"[警告] 扫描目录是文件系统根目录：{root}", file=sys.stderr)

    limit_bytes = int(args.size_mb * MB)

    print(f"扫描目录 : {root}")
    print(f"大小阈值 : {args.size_mb:g} MBytes ({limit_bytes} 字节)")
    print(f"递归子目录: {'是' if args.no_recursive else '是'}")
    print("-" * 70)

    # ---- 扫描 ------------------------------------------------------------- #
    targets = find_large_files(root, limit_bytes, True)

    if not targets:
        print("未发现超过阈值的文件，无需删除。")
        return 0

    total_size = 0
    for file_path, size in targets:
        total_size += size
        print(f"{human_readable(size):>12}  {file_path}")

    print("-" * 70)
    print(f"共 {len(targets)} 个文件，合计 {human_readable(total_size)}")

    if args.dry_run:
        print("（dry-run 模式：未删除任何文件）")
        return 0

    # ---- 确认 ------------------------------------------------------------- #
    if not args.yes:
        try:
            answer = input("确认删除以上全部文件？输入 yes 继续：").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print("\n已取消。")
            return 1
        if answer not in ("y", "yes"):
            print("已取消。")
            return 1

    # ---- 删除 ------------------------------------------------------------- #
    deleted, freed, failed = 0, 0, 0
    for file_path, size in targets:
        try:
            remove_file(file_path)
        except OSError as exc:
            failed += 1
            print(f"[失败] {file_path}：{exc}", file=sys.stderr)
        else:
            deleted += 1
            freed += size
            print(f"[已删除] {file_path}")

    print("-" * 70)
    print(f"完成：成功删除 {deleted}/{len(targets)} 个文件，释放 {human_readable(freed)}"
          + (f"，失败 {failed} 个" if failed else ""))
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())