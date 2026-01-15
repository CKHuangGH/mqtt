#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import sys

TARGET_PATTERNS = [
    "volumeMounts:",
    "name: shared",
    "mountPath: /app/out",
    "subPath: out",
    "mountPath: /app/results",
    "subPath: result",
]

LOGS_MOUNT_KEYWORDS = [
    "mountPath: /app/logs",
    "subPath: logs",
]

def parse_replacements(replace_args):
    """
    --replace a=b --replace c=d  ->  [("a","b"), ("c","d")]
    """
    pairs = []
    if not replace_args:
        return pairs
    for item in replace_args:
        if "=" not in item:
            raise ValueError(f"--replace 參數格式要是 old=new，收到：{item}")
        old, new = item.split("=", 1)
        pairs.append((old, new))
    return pairs

def contains_all_keywords(text, keywords):
    return all(k in text for k in keywords)

def find_insert_index_for_logs(lines):
    """
    找到「/app/results + subPath result」那個 mount item 的 subPath 行，
    回傳 (insert_after_line_index, dash_indent_spaces)
    若找不到，回傳 (None, None)
    """
    # 策略：
    # 1) 找到包含 "mountPath: /app/results" 的行 i
    # 2) 往下找同一個 item 的 "subPath: result" 行 j（通常在 i 後面不遠）
    # 3) 以 mountPath 行的縮排推回 dash_indent（mountPath 一般比 "- name" 多 2 格）
    for i, line in enumerate(lines):
        if "mountPath: /app/results" in line:
            mount_indent = len(line) - len(line.lstrip(" "))
            dash_indent = max(mount_indent - 2, 0)

            # 往下找 subPath: result（限制搜尋範圍避免跑太遠）
            for j in range(i, min(i + 20, len(lines))):
                if "subPath: result" in lines[j]:
                    return j, dash_indent
    return None, None

def already_has_logs_mount(text):
    # 粗略判斷：只要出現 mountPath /app/logs 就當作已存在
    return "mountPath: /app/logs" in text

def apply_replacements(text, replace_pairs):
    for old, new in replace_pairs:
        text = text.replace(old, new)
    return text

def process_file(path, replace_pairs, dry_run=False, backup=True):
    with open(path, "r", encoding="utf-8") as f:
        original = f.read()

    # 先做「必須同時命中全部關鍵字」的篩選
    if not contains_all_keywords(original, TARGET_PATTERNS):
        return False, "skip(no-keywords)"

    # 先做替換（如果你有指定）
    updated = apply_replacements(original, replace_pairs)

    # 如果已經有 logs mount，直接不動（但替換可能已經改了；此處仍會寫回若有替換變更）
    need_add_logs = not already_has_logs_mount(updated)

    lines = updated.splitlines(keepends=True)

    if need_add_logs:
        insert_after, dash_indent = find_insert_index_for_logs(lines)
        if insert_after is None:
            # 理論上不該發生（因為 keywords 已命中），但保險起見
            return False, "skip(cannot-locate-insert-point)"

        item_indent = " " * dash_indent
        prop_indent = " " * (dash_indent + 2)

        logs_block = [
            f"{item_indent}- name: shared\n",
            f"{prop_indent}mountPath: /app/logs\n",
            f"{prop_indent}subPath: logs\n",
        ]

        # 插入在 subPath: result 之後
        lines[insert_after + 1:insert_after + 1] = logs_block

    final_text = "".join(lines)

    if final_text == original:
        return False, "skip(no-change)"

    if dry_run:
        return True, "dry-run(would-change)"

    # 寫回前備份
    if backup:
        bak_path = path + ".bak"
        if not os.path.exists(bak_path):
            with open(bak_path, "w", encoding="utf-8") as bf:
                bf.write(original)

    with open(path, "w", encoding="utf-8") as f:
        f.write(final_text)

    return True, "updated"

def iter_yaml_files(root_dir):
    for base, _, files in os.walk(root_dir):
        for fn in files:
            lower = fn.lower()
            if lower.endswith(".yml") or lower.endswith(".yaml"):
                yield os.path.join(base, fn)

def main():
    parser = argparse.ArgumentParser(
        description="遞迴搜尋 YAML 檔，命中指定 volumeMounts 關鍵字後，新增 /app/logs 的 shared volumeMount（保留縮排）。"
    )
    parser.add_argument(
        "--root",
        default=None,
        help="搜尋起點資料夾（預設：此腳本所在資料夾）",
    )
    parser.add_argument(
        "--replace",
        action="append",
        help="可重複指定：--replace old=new 進行字串替換（先替換再插入 logs mount）",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只顯示會改哪些檔案，不寫入",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="不產生 .bak 備份（預設會備份一次）",
    )

    args = parser.parse_args()
    root_dir = args.root or os.path.dirname(os.path.abspath(__file__))
    replace_pairs = parse_replacements(args.replace)

    changed = 0
    scanned = 0

    for path in iter_yaml_files(root_dir):
        scanned += 1
        ok, status = process_file(
            path,
            replace_pairs=replace_pairs,
            dry_run=args.dry_run,
            backup=(args.no_backup),
        )
        if ok:
            changed += 1
            print(f"[{status}] {path}")

    print(f"\n掃描：{scanned} 個 YAML 檔；{'將會修改' if args.dry_run else '已修改'}：{changed} 個")
    return 0

if __name__ == "__main__":
    sys.exit(main())