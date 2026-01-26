docker compose up -d  generate_genesis
sleep 30

set -e

IPS=(
  13.115.178.211
  13.115.178.211
  13.115.178.211
  13.115.178.211
  13.115.178.211
  13.115.178.211
  13.115.178.211
)

cp -rf app/keys app1
cp -rf app/config app1
cp -rf app/config app2
cp -rf app/config app3
cp -rf app/config app4
cp -rf app/config app5
cp -rf app/config app6
cp -rf app/config app7


docker compose up -d  validator_node_one
docker compose up -d  validator_node_two
docker compose up -d  validator_node_three
docker compose up -d  validator_node_four
docker compose up -d  validator_node_five
docker compose up -d  validator_node_six
docker compose up -d  validator_node_seven

sleep 10

docker stop  validator_node_two
docker stop  validator_node_three
docker stop  validator_node_four
docker stop  validator_node_five
docker stop  validator_node_six
docker stop  validator_node_seven

sleep 10


BOOTSTRAP_NODES=()

for i in {1..7}; do
  APP="app${i}"
  ENODE_FILE="${APP}/keys/enode.txt"
  IP="${IPS[$((i-1))]}"
  PORT=$((30300 + i))

  if [[ ! -f "$ENODE_FILE" ]]; then
    echo "❌ missing enode file: ${ENODE_FILE}"
    exit 1
  fi

  ENODE_ID=$(cut -d'@' -f1 "$ENODE_FILE")
  BOOTSTRAP_NODES+=("    \"${ENODE_ID}@${IP}:${PORT}\"")
done

for i in {1..7}; do
  APP="app${i}"
  CONFIG_FILE="${APP}/config/config.toml"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ missing config file: ${CONFIG_FILE}"
    exit 1
  fi

  echo "🔧 Updating ${CONFIG_FILE}"

  awk -v nodes="$(printf "%s,\n" "${BOOTSTRAP_NODES[@]}")" '
    BEGIN {in_bs=0}
    /^\s*BootstrapNodes\s*=\s*\[/ {
      print "BootstrapNodes = ["
      printf "%s", nodes
      print "]"
      in_bs=1
      next
    }
    in_bs {
      if ($0 ~ /\]/) in_bs=0
      next
    }
    {print}
  ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"

  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
done

echo "✅ BootstrapNodes updated with 7 enode for all apps"


docker compose restart  validator_node_two
sleep 5
docker compose restart  validator_node_three
sleep 5
docker compose restart  validator_node_four
sleep 5
docker compose restart  validator_node_five
sleep 5
docker compose restart  validator_node_six
sleep 5
docker compose restart  validator_node_seven



# 设置输出格式
FORMAT="${1:--full}"

echo "=== 提取验证者地址 ==="

for APP_NUM in {2..7}; do
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