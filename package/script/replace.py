#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import shutil
from pathlib import Path

# 預設處理的副檔名（可自行加）
DEFAULT_EXTS = [".yaml", ".yml", ".sh", ".txt", ""]  # "" = 沒副檔名也算
ENCODINGS = ("utf-8", "latin-1")


def read_text(p: Path) -> str:
    for enc in ENCODINGS:
        try:
            return p.read_text(encoding=enc, errors="ignore")
        except Exception:
            continue
    return ""


def write_text(p: Path, content: str, backup: bool = True):
    if backup:
        bak = p.with_suffix(p.suffix + ".bak")
        if not bak.exists():
            shutil.copy2(p, bak)
    p.write_text(content, encoding="utf-8")


def apply_sub(content: str, src: str, dst: str, ignore_case: bool, whole_word: bool):
    flags = re.IGNORECASE if ignore_case else 0
    pat = re.escape(src)
    if whole_word:
        pat = rf"\b{pat}\b"
    regex = re.compile(pat, flags)
    return regex.subn(dst, content)


def main():
    print("=== 檔案批次替換工具 (遞迴所有子資料夾) ===\n")

    root = Path(input("請輸入要處理的資料夾（直接按 Enter = 當前資料夾）：").strip() or ".").resolve()
    if not root.exists():
        print(f"[錯誤] 找不到資料夾：{root}")
        return

    src = input("輸入要尋找的文字：").strip()
    dst = input("要替換成的文字：").strip()
    ignore_case = input("忽略大小寫？(y/N)：").strip().lower() == "y"
    whole_word = input("整字匹配？(y/N)：").strip().lower() == "y"
    apply = input("是否直接寫入檔案？(y/N)：").strip().lower() == "y"

    exts = DEFAULT_EXTS

    total_files, total_hits, changed = 0, 0, 0

    for p in root.rglob("*"):  # 遞迴所有子目錄
        if not p.is_file():
            continue
        if p.suffix.lower() not in exts:
            continue

        text = read_text(p)
        new_text, hits = apply_sub(text, src, dst, ignore_case, whole_word)
        if hits > 0:
            total_files += 1
            total_hits += hits
            print(f"→ {p}  命中 {hits} 次")
            if apply:
                write_text(p, new_text)
                changed += 1

    print("\n===== 結果 =====")
    print(f"匹配檔案數：{total_files}")
    print(f"總替換次數：{total_hits}")
    if apply:
        print(f"已寫入檔案：{changed}（每個檔案自動產生 .bak 備份）")
    else:
        print("（僅預覽，未寫入）")


if __name__ == "__main__":
    try:
        main()
    finally:
        input("\n完成，按 Enter 關閉視窗...")
