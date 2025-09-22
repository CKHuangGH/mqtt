#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from pathlib import Path

def main():
    print("=== .bak 檔案清理工具 ===\n")
    root = Path(input("請輸入要清理的資料夾（直接按 Enter = 當前資料夾）：").strip() or ".").resolve()
    if not root.exists():
        print(f"[錯誤] 找不到資料夾：{root}")
        return

    bak_files = list(root.rglob("*.bak"))
    if not bak_files:
        print("✅ 沒有找到任何 .bak 檔案。")
        return

    print(f"找到 {len(bak_files)} 個 .bak 檔案：")
    for f in bak_files:
        print("→", f)

    confirm = input("\n是否刪除這些檔案？(y/N)：").strip().lower()
    if confirm != "y":
        print("已取消。")
        return

    deleted = 0
    for f in bak_files:
        try:
            f.unlink()
            deleted += 1
        except Exception as e:
            print(f"⚠️ 無法刪除 {f}: {e}")

    print(f"\n🗑️ 已刪除 {deleted} 個 .bak 檔案。")

if __name__ == "__main__":
    try:
        main()
    finally:
        input("\n完成，按 Enter 關閉視窗...")
