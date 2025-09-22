#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import re
from pathlib import Path

BROKER_EXCLUDED_FILES = {"runner-service.yaml"}  # 除了它，其他都需包含 broker
TEXT_EXTS = {".yaml", ".yml", ".sh", ".txt", ""}

def infer_tokens_from_folder(folder_name: str):
    """從資料夾名稱推斷 (scenario, broker)
       e.g. '01_qossuite_smart_city_mqttv5_high_emqx'
         -> ('qossuite_smart_city_mqttv5_high', 'emqx')
       若資料夾以 '_' 結尾（例如 '*_dds_'），視為無 broker（返回 broker=None），以跳過 broker 檢查。
    """
    name = re.sub(r'^[0-9]{2}[_\-\s]*', '', folder_name.strip())  # 去掉前綴 01_
    parts = name.split('_')

    if len(parts) < 2:
        return None, None

    raw_broker = parts[-1]
    broker = raw_broker if raw_broker != "" else None

    scenario = '_'.join(parts[:-1]).strip('_- ')
    if not scenario:
        return None, broker

    return scenario, broker

def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        try:
            return p.read_text(encoding="latin-1", errors="ignore")
        except Exception:
            return ""

def collect_runner_deployments(folder: Path, runner_pattern: re.Pattern):
    """回傳該資料夾內所有符合 runner deployment 檔名的 Path 清單"""
    runners = []
    for p in sorted(folder.iterdir()):
        if p.is_file() and p.suffix.lower() in TEXT_EXTS:
            if runner_pattern.match(p.name):
                runners.append(p)
    return runners

def check_folder(folder: Path, runner_pattern: re.Pattern):
    scenario, broker = infer_tokens_from_folder(folder.name)
    issues, notes = [], []

    if not scenario:
        issues.append(f"[解析失敗] 無法從資料夾名稱推斷 scenario：{folder.name}")
        return issues, notes, scenario, broker

    no_broker_mode = broker is None
    if no_broker_mode:
        notes.append(f"[略過] {folder.name}（資料夾以 '_' 結尾，視為無 Broker，跳過 Broker 檢查）")

    # 先找出所有 runnerN-deployment.yaml（不限數量）
    runner_files = collect_runner_deployments(folder, runner_pattern)

    # 規則 1：所有 runnerN-deployment.yaml 內容必須包含 scenario
    for rp in runner_files:
        content = read_text(rp)
        if scenario not in content:
            issues.append(f"[場景缺失] {folder.name}/{rp.name} 未在內容中包含場景代碼：{scenario}")
        else:
            notes.append(f"[OK] {folder.name}/{rp.name} 內容含場景代碼")
        if scenario not in rp.name:
            notes.append(f"[提示] {folder.name}/{rp.name} 檔名未含場景代碼（非必須）")

    # 規則 2：Broker 檢查（除 runner-service.yaml 之外，且非 no_broker_mode）
    for p in sorted(folder.iterdir()):
        if not p.is_file():
            continue
        if p.suffix.lower() not in TEXT_EXTS:
            continue
        fname = p.name
        if fname in BROKER_EXCLUDED_FILES:
            notes.append(f"[略過] {folder.name}/{fname}（規則排除 Broker 檢查）")
            continue
        if no_broker_mode:
            continue  # 整夾跳過 broker 檢查

        content = read_text(p)
        if broker not in content:
            issues.append(f"[Broker缺失] {folder.name}/{fname} 未在內容中包含 Broker：{broker}")
        else:
            notes.append(f"[OK] {folder.name}/{fname} 內容含 Broker")
        if broker not in fname:
            notes.append(f"[提示] {folder.name}/{fname} 檔名未含 Broker 名稱（非必須）")

    return issues, notes, scenario, broker

def is_target_folder(p: Path, min_idx: int, max_idx: int) -> bool:
    """只挑兩位數字開頭的資料夾，且介於 min_idx..max_idx；可在任意層級"""
    m = re.match(r'^(\d{2})[_\-\s]', p.name)
    if not m:
        return False
    idx = int(m.group(1))
    return min_idx <= idx <= max_idx

def find_target_folders(root: Path, min_idx: int, max_idx: int):
    """遞迴尋找所有符合 NN_* 的資料夾"""
    folders = []
    for p in root.rglob("*"):
        if p.is_dir() and is_target_folder(p, min_idx, max_idx):
            folders.append(p)
    return sorted(folders)

def main():
    ap = argparse.ArgumentParser(
        description="檢查 NN_* 資料夾：所有 runnerN-deployment.yaml 需含場景代碼；若資料夾以 '_' 結尾則視為無 Broker，否則除 runner-service 外皆需含 Broker"
    )
    ap.add_argument("root", nargs="?", default=".",
                    help="根目錄（包含 NN_* 資料夾，可在任意層級），預設為當前目錄")
    ap.add_argument("--min", type=int, default=1, help="最小索引（預設1）")
    ap.add_argument("--max", type=int, default=99, help="最大索引（預設99）")
    ap.add_argument("--pause", action="store_true",
                    help="每個資料夾檢查後停住等待指令（Enter繼續 / n跳下一個 / q結束）")
    ap.add_argument("--break-on-error", action="store_true",
                    help="遇到❌問題立即停止")
    ap.add_argument("--fail-on-warning", dest="fail_on_warning", action="store_true",
                    help="將提示(非硬性規則)也視為失敗")
    ap.add_argument("--runner-pattern", default=r"^runner(\d+)-deployment\.yaml$",
                    help="自訂 runner 檢查檔名的正則（預設 '^runner(\\d+)-deployment\\.yaml$'）")
    args = ap.parse_args()

    root = Path(args.root).expanduser().resolve()
    if not root.exists():
        print(f"[錯誤] 找不到路徑：{root}")
        raise SystemExit(2)

    try:
        runner_pattern = re.compile(args.runner_pattern)
    except re.error as e:
        print(f"[錯誤] runner-pattern 非法正則：{e}")
        raise SystemExit(2)

    folders = find_target_folders(root, args.min, args.max)

    if not folders:
        print("未找到符合 'NN_*' 的子資料夾。")
        raise SystemExit(1)

    total_issues = 0
    total_notes = 0

    print(f"🔎 開始檢查：{root}（範圍 {args.min:02d}..{args.max:02d}）\n")

    for folder in folders:
        print(f"=== {folder.name} ===")
        issues, notes, scenario, broker = check_folder(folder, runner_pattern)

        broker_display = broker if broker is not None else "—"
        print(f"解析 → scenario='{scenario}', broker='{broker_display}'")

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

    if total_issues == 0 and (not args.fail_on_warning or total_notes == 0):
        print("🎉 全部通過檢查")
        code = 0
    else:
        print(f"⚠️ 完成：{total_issues} 個問題，{total_notes} 個提示")
        code = 1 if total_issues > 0 or args.fail_on_warning else 0

    raise SystemExit(code)

if __name__ == "__main__":
    try:
        main()
    finally:
        # 讓 Windows 雙擊不會一閃即逝（雙擊執行時）
        try:
            input("\n檢查結束，按 Enter 鍵關閉視窗...")
        except EOFError:
            pass
