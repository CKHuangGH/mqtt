#!/usr/bin/env bash
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

# 校验时间格式 HH:MM:SS
if [[ ! "${NEW_DURATION}" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
  echo "❌ NEW_DURATION 必须是 HH:MM:SS 格式，例如 08:00:00" >&2
  exit 1
fi

OLD='duration = "03:10:00"'

echo "🔎 在 ${ROOT_DIR} 查找包含：${OLD}"
echo "🔁 替换为：duration = \"${NEW_DURATION}\""
echo

# 遍历匹配的文件并替换
grep -RIl --exclude-dir='.git' -- "${OLD}" "${ROOT_DIR}" | while read -r f; do
  echo "👉 修改: $f"
  sed -i "s/duration = \"03:10:00\"/duration = \"${NEW_DURATION}\"/g" "$f"
done

echo "✅ 全部完成"
