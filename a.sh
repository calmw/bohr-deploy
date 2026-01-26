docker compose up -d  generate_genesis

set -e

for APP_NUM in {1..7}; do
    APP_DIR="app${APP_NUM}"
    KEYSTORE_DIR="./${APP_DIR}/keys/validator/keystore"
    echo "处理节点: $APP_DIR"
    # 检查 keystore 目录是否存在
    if [ ! -d "$KEYSTORE_DIR" ]; then
        echo "  ❌ 跳过: 未找到目录 $KEYSTORE_DIR"
        ((FAIL_COUNT++))
        continue
    fi
    # 查找 UTC 文件
    UTC_FILE=$(find "$KEYSTORE_DIR" -name "UTC--*" -type f | head -n 1)

    if [ -z "$UTC_FILE" ]; then
        echo "  ❌ 跳过: 在 $KEYSTORE_DIR 中未找到 keystore 文件"
        ((FAIL_COUNT++))
        continue
    fi
    # 从文件名提取地址
    ADDRESS=$(basename "$UTC_FILE" | cut -d'-' -f4)
    FULL_ADDRESS="0x${ADDRESS}"
    echo "  → ${APP_DIR}地址: $FULL_ADDRESS"
    ((SUCCESS_COUNT++))
done