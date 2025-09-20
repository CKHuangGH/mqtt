#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import re
from pathlib import Path

SCENARIO_REQUIRED_FILES = {f"runner{i}-deployment.yaml" for i in range(1, 6)}
BROKER_EXCLUDED_FILES = {"runner-service.yaml"}  # 除了它，其他都需包含 broker
TEXT_EXTS = {".yaml", ".yml", ".sh", ".txt", ""}

def infer_tokens_from_folder(folder_name: str):
    """從資料夾名稱推斷 (scenario, broker)
       e.g. '01_qossuite_smart_city_mqttv5_high_emqx'
         -> ('qossuite_smart_city_mqttv5_high', 'emqx')
    """
    name = re.sub(r'^[0-9]{2}[_\-\s]*', '', folder_name.strip())  # 去掉前綴 01_
    parts = name.split('_')
    if len(parts) < 2:
        return None, None
    broker = parts[-1]
    scenario = '_'.join(parts[:-1])
    return scenario, broker

def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        try:
            return p.read_text(encoding="latin-1", errors="ignore")
        except Exception:
            return ""

def check_folder(folder: Path):
    scenario, broker = infer_tokens_from_folder(folder.name)
    issues, notes = [], []

    if not scenario or not broker:
        issues.append(f"[解析失敗] 無法從資料夾名稱推斷 scenario/broker：{folder.name}")
        return issues, notes, scenario, broker

    for p in sorted(folder.iterdir()):
        if not p.is_file():
            continue
        fname = p.name
        suffix = p.suffix.lower()

        # 只檢查常見文字檔
        if suffix not in TEXT_EXTS:
            continue

        content = read_text(p)

        # 規則 1：runner1~5 的內容必須包含 scenario
        if fname in SCENARIO_REQUIRED_FILES:
            if scenario not in content:
                issues.append(f"[場景缺失] {folder.name}/{fname} 未在內容中包含場景代碼：{scenario}")
            else:
                notes.append(f"[OK] {folder.name}/{fname} 內容含場景代碼")
            if scenario not in fname:
                notes.append(f"[提示] {folder.name}/{fname} 檔名未含場景代碼（非必須）")

        # 規則 2：除了 runner-service.yaml，其它檔案內容必須包含 broker
        if fname not in BROKER_EXCLUDED_FILES:
            if broker not in content:
                issues.append(f"[Broker缺失] {folder.name}/{fname} 未在內容中包含 Broker：{broker}")
            else:
                notes.append(f"[OK] {folder.name}/{fname} 內容含 Broker")
            if broker not in fname:
                notes.append(f"[提示] {folder.name}/{fname} 檔名未含 Broker 名稱（非必須）")
        else:
            notes.append(f"[略過] {folder.name}/{fname}（規則排除 Broker 檢查）")

    return issues, notes, scenario, broker

def is_target_folder(p: Path, min_idx: int, max_idx: int) -> bool:
    """只挑兩位數字開頭的資料夾，且介於 min_idx..max_idx"""
    m = re.match(r'^(\d{2})[_\-\s]', p.name)
    if not m:
        return False
    idx = int(m.group(1))
    return min_idx <= idx <= max_idx

def main():
    ap = argparse.ArgumentParser(
        description="逐個子資料夾檢查：runner1-5需含場景代碼，除runner-service外皆需含Broker")
    ap.add_argument("root", nargs="?", default=".",
                    help="根目錄（包含 01_... ~ 08_... 子資料夾），預設為當前目錄")
    ap.add_argument("--min", type=int, default=1, help="最小索引（預設1）")
    ap.add_argument("--max", type=int, default=8, help="最大索引（預設8）")
    ap.add_argument("--pause", action="store_true",
                    help="每個資料夾檢查後停住等待指令（Enter繼續 / n跳下一個 / q結束）")
    ap.add_argument("--break-on-error", action="store_true",
                    help="遇到❌問題立即停止")
    ap.add_argument("--fail-on-warning", action="store_true",
                    help="將提示(非硬性規則)也視為失敗")
    args = ap.parse_args()

    root = Path(args.root).expanduser().resolve()
    if not root.exists():
        print(f"[錯誤] 找不到路徑：{root}")
        raise SystemExit(2)

    folders = [p for p in sorted(root.iterdir())
               if p.is_dir() and is_target_folder(p, args.min, args.max)]

    if not folders:
        print("未找到符合 'NN_*' 的子資料夾。")
        raise SystemExit(1)

    total_issues = 0
    total_notes = 0

    print(f"🔎 開始檢查：{root}（範圍 {args.min:02d}..{args.max:02d}）\n")

    for folder in folders:
        print(f"=== {folder.name} ===")
        issues, notes, scenario, broker = check_folder(folder)

        print(f"解析 → scenario='{scenario}', broker='{broker}'")

        if issues:
            for msg in issues:
                print("❌", msg)
        else:
            print("✅ 必要規則皆通過")

        if notes:
            print("--- 資訊/提示 ---")
            for msg in notes:
                print("•", msg)

        total_issues += len(issues)
        total_notes += len(notes)
        print()

        if args.break_on_error and issues:
            print("⛔ 遇到問題，已停止（--break-on-error 生效）。")
            raise SystemExit(1)

        if args.pause:
            while True:
                cmd = input("按 Enter 繼續，輸入 n 跳至下一個，或 q 結束 > ").strip().lower()
                if cmd in {"", "n"}:
                    break
                if cmd == "q":
                    print("已中止。")
                    raise SystemExit(1)

    if total_issues == 0 and (not args.fail-on-warning or total_notes == 0):
        print("🎉 全部通過檢查")
        code = 0
    else:
        print(f"⚠️ 完成：{total_issues} 個問題，{total_notes} 個提示")
        code = 1 if total_issues > 0 or args.fail-on-warning else 0

    raise SystemExit(code)

if __name__ == "__main__":
    try:
        main()
    finally:
        # 讓 Windows 雙擊不會一閃即逝
        input("\n檢查結束，按 Enter 鍵關閉視窗...")
