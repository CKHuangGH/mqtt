set -euo pipefail

# 用法: ./modify_duration.sh NEW_DURATION [ROOT_DIR]
# 例子: ./modify_duration.sh 08:00:00 .

NEW_DURATION="${1:-}"
ROOT_DIR="${2:-.}"

if [[ -z "${NEW_DURATION}" ]]; then
  echo "用法: $0 NEW_DURATION [ROOT_DIR]" >&2
  echo "例子: $0 08:00:00 ." >&2
  exit 1
fi

# 校驗時間格式 HH:MM:SS
if [[ ! "${NEW_DURATION}" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
  echo "❌ NEW_DURATION 必須是 HH:MM:SS 格式，例如 08:00:00" >&2
  exit 1
fi

NEW="duration = \"${NEW_DURATION}\""

echo "🔎 在 ${ROOT_DIR} 裡查找並替換所有 duration = \"??:??:??\""
echo "   → ${NEW}"
echo

# 遞迴遍歷檔案，直接替換
grep -RIl --exclude-dir='.git' -- 'duration = "' "${ROOT_DIR}" | while read -r f; do
  echo "✏️  修改 $f"
  # 匹配 duration = "HH:MM:SS" 並整行替換成新值
  sed -i -E "s/duration = \"[0-9]{2}:[0-9]{2}:[0-9]{2}\"/${NEW}/g" "$f"
done

echo
echo "✅ 替換完成"