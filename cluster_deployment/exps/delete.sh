#!/bin/bash

# 從 01 到 08 都跑一次
for i in 01 02 03 04 05 06 07 08; do
    echo ">>> Entering $i"
    cd "$i" || exit 1   # 進入資料夾，如果失敗就退出
    if [ -x "./03_del.sh" ]; then
        ./03_del.sh
    else
        echo "    Skipped: ./03_del.sh not found in $i"
    fi
    cd ..   # 回到上一層 (exps/)
done