#!/bin/bash

# 脚本：extract_addresses.sh
# 功能：提取所有节点的验证者地址
# 用法：./extract_addresses.sh [格式]
#       格式：-full (默认，带0x前缀) 或 -raw (纯十六进制，不带0x)

# 设置输出格式
FORMAT="${1:--full}"

echo "=== 提取验证者地址 ==="

for APP_NUM in {1..7}; do
    APP_DIR="app${APP_NUM}"
    KEYSTORE_DIR="./${APP_DIR}/keys/validator/keystore"
    
    # 查找 keystore 文件
    UTC_FILE=$(find "$KEYSTORE_DIR" -name "UTC--*" -type f 2>/dev/null | head -n 1)
    
    if [ -z "$UTC_FILE" ]; then
        # 输出错误信息到标准错误，不干扰地址输出
        echo "警告: 未找到 $APP_DIR 的 keystore 文件" >&2
        continue
    fi
    
    # 提取地址 (最后一个'--'之后的部分)
    ADDRESS=$(basename "$UTC_FILE" | awk -F'--' '{print $NF}')
    
    # 根据格式输出
    if [ "$FORMAT" = "-raw" ]; then
        echo "$ADDRESS"          # 纯十六进制，不带0x
    else
        echo "0x${ADDRESS}"      # 带0x前缀 (默认)
    fi
done

echo "=== 地址提取完成 ==="