#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import re
import sys

# 目標：把這種註解行變成可執行行，並改路徑
# # kubectl cp -c runnermqtt${i} "$pod":/app/out     "results/"
# -> kubectl cp -c runnermqtt${i} "$pod":/app/logs "results/log/"
COMMENT_CP_RE = re.compile(
    r'^(\s*)#\s*(kubectl\s+cp\s+-c\s+runnermqtt\$\{i\}\s+"\$pod":/app/out\s+)"results/"\s*$'
)

def ensure_mkdir(lines: list[str]) -> list[str]:
    has_results = any(l.strip() == "mkdir -p results" for l in lines)
    has_logdir = any(l.strip() == "mkdir -p results/log" for l in lines)

    if has_logdir:
        return lines

    if has_results:
        out = []
        inserted = False
        for l in lines:
            out.append(l)
            if (not inserted) and l.strip() == "mkdir -p results":
                prefix = l[: len(l) - len(l.lstrip(" "))]
                out.append(prefix + "mkdir -p results/log\n")
                inserted = True
        return out

    # 若原本沒有 mkdir -p results，補在檔頭（保留 shebang）
    out = []
    i = 0
    if lines and lines[0].startswith("#!"):
        out.append(lines[0])
        i = 1
    out.append("mkdir -p results\n")
    out.append("mkdir -p results/log\n")
    out.extend(lines[i:])
    return out

def patch_lines(lines: list[str]) -> tuple[list[str], bool]:
    out = []
    changed = False
    for l in lines:
        m = COMMENT_CP_RE.match(l.rstrip("\n"))
        if m:
            indent = m.group(1)
            prefix = m.group(2)
            # 解註解 + out->logs + results/ -> results/log/
            newline = indent + prefix.replace("/app/out", "/app/logs") + '"results/log/"\n'
            out.append(newline)
            changed = True
        else:
            out.append(l)
    return out, changed

def should_process(path: str, exts: set[str]) -> bool:
    pl = path.lower()
    return any(pl.endswith(ext) for ext in exts)

def process_file(path: str, exts: set[str], dry_run: bool) -> tuple[bool, str]:
    if not should_process(path, exts):
        return False, "skip(ext)"

    with open(path, "r", encoding="utf-8") as f:
        original = f.read()

    # 快速過濾：檔案裡至少要有這些字才可能命中
    if 'runnermqtt${i}' not in original or "/app/out" not in original or "kubectl cp" not in original:
        return False, "skip(no-keyword)"

    lines = original.splitlines(keepends=True)
    new_lines, changed = patch_lines(lines)

    if not changed:
        return False, "skip(no-match)"

    new_lines = ensure_mkdir(new_lines)
    updated = "".join(new_lines)

    if updated == original:
        return False, "skip(no-change)"

    if dry_run:
        return True, "dry-run(would-change)"

    with open(path, "w", encoding="utf-8") as f:
        f.write(updated)

    return True, "updated"

def iter_files(root: str):
    for base, _, files in os.walk(root):
        for fn in files:
            yield os.path.join(base, fn)

def main():
    ap = argparse.ArgumentParser(
        description='把 "# kubectl cp ... /app/out ... results/" 解註解並改成 /app/logs -> results/log/，同時補 mkdir -p results/log'
    )
    ap.add_argument("--root", default=None, help="搜尋起點（預設：腳本所在資料夾）")
    ap.add_argument("--ext", action="append", default=None, help="要掃的副檔名，例如 --ext .sh --ext .bash")
    ap.add_argument("--dry-run", action="store_true", help="只顯示會改哪些檔，不寫入")
    args = ap.parse_args()

    root = args.root or os.path.dirname(os.path.abspath(__file__))
    exts = set(args.ext) if args.ext else {".sh", ".bash"}

    scanned = 0
    changed = 0
    for p in iter_files(root):
        scanned += 1
        ok, status = process_file(p, exts, args.dry_run)
        if ok:
            changed += 1
            print(f"[{status}] {p}")

    print(f"\n掃描：{scanned} 個檔案；{'將會修改' if args.dry_run else '已修改'}：{changed} 個")
    return 0

if __name__ == "__main__":
    sys.exit(main())
