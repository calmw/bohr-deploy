#!/usr/bin/env bash


COMPOSE_FILE="docker-compose.yaml"

echo "===================================="
echo " BOT 主网 Validator 启动脚本"
echo "===================================="
echo
read -p "请输入节点序号（如 001 / 002 / 003）： " VALIDATOR_INDEX

echo "登陆docker"
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 630968570112.dkr.ecr.ap-northeast-1.amazonaws.com

# 校验：必须是 3 位数字
if [[ ! "$VALIDATOR_INDEX" =~ ^[0-9]{3}$ ]]; then
  echo "❌ 错误：节点序号必须是 3 位数字，例如 001"
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ 未找到 $COMPOSE_FILE"
  exit 1
fi

echo
echo "👉 设置 VALIDATOR_INDEX = $VALIDATOR_INDEX"

# 替换 docker-compose.yaml 中的 VALIDATOR_INDEX
sed -i.bak -E '/environment:/,/^[^[:space:]]/ s/(VALIDATOR_INDEX:\s*").*(")/\1'"$VALIDATOR_INDEX"'\2/' "$COMPOSE_FILE"

if [ $? -ne 0 ]; then
  echo "❌ 修改 docker-compose.yaml 失败"
  exit 1
fi

echo "✅ docker-compose.yaml 已更新（备份：docker-compose.yaml.bak）"
echo
echo "🚀 启动 validator 节点..."
echo "------------------------------------"

docker-compose up -d validator_node

echo "sleep 10s"
sleep 10

get_public_ip() {
  for cmd in \
    "curl -s https://api.ipify.org" \
    "curl -s ifconfig.me" \
    "curl -s https://checkip.amazonaws.com" \
    "dig +short myip.opendns.com @resolver1.opendns.com"
  do
    ip=$(eval $cmd 2>/dev/null)
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$ip"
      return 0
    fi
  done

  echo "❌ 无法获取外网 IP" >&2
  return 1
}

echo "=== 提取 enode 地址 ==="
PUBLIC_IP=$(get_public_ip)
echo "公网 IP: $PUBLIC_IP"


APP="app"
PORT=30303
ENODE_FILE="${APP}/keys/enode.txt"
if [[ ! -f "$ENODE_FILE" ]]; then
  echo "❌ missing enode file: ${ENODE_FILE}"
  exit 1
fi

ENODE_ID=$(cut -d'@' -f1 "$ENODE_FILE")
BOOTSTRAP_NODE=("    \"${ENODE_ID}@${PUBLIC_IP}:${PORT}\"")
echo "⚠️ 请手动将以下 enode 配置到 config 中："
echo "${BOOTSTRAP_NODE}"
echo "=== 提取 enode 地址完成 ==="



# 设置输出格式
FORMAT="${1:--full}"
echo "=== 提取验证者地址 ==="
APP_DIR="app"
KEYSTORE_DIR="./${APP_DIR}/keys/validator/keystore"
# 查找 keystore 文件
UTC_FILE=$(find "$KEYSTORE_DIR" -name "UTC--*" -type f 2>/dev/null | head -n 1)
if [ -z "$UTC_FILE" ]; then
    # 输出错误信息到标准错误，不干扰地址输出
    echo "警告: 未找到 $APP_DIR 的 keystore 文件" >&2
    echo "跳过验证者地址提取"
    exit 0
fi
# 提取地址 (最后一个'--'之后的部分)
ADDRESS=$(basename "$UTC_FILE" | awk -F'--' '{print $NF}')
# 根据格式输出
if [ "$FORMAT" = "-raw" ]; then
    echo "$ADDRESS"          # 纯十六进制，不带0x
else
    echo "0x${ADDRESS}"      # 带0x前缀 (默认)
fi
echo "=== 地址提取完成 ==="

CONFIG_FILE="app/config/config.toml"

# VALIDATOR_INDEX: 001 -> 0
BOOTSTRAP_INDEX=$((10#$VALIDATOR_INDEX - 1))

echo "👉 使用 BootstrapNodes 索引: ${BOOTSTRAP_INDEX}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ 未找到 $CONFIG_FILE"
  exit 1
fi

NEW_NODE="${ENODE_ID}@${PUBLIC_IP}:${PORT}"

echo "👉 将替换为: ${NEW_NODE}"

# 只在 BootstrapNodes 数组内，替换第 N 个元素
awk -v idx="$BOOTSTRAP_INDEX" -v new="\"${NEW_NODE}\"" '
/BootstrapNodes = \[/ { in_list=1; count=0 }
in_list && /^\s*"/ {
  if (count == idx) {
    print "    " new ","
    count++
    next
  }
  count++
}
in_list && /\]/ { in_list=0 }
{ print }
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "✅ config.toml BootstrapNodes[${BOOTSTRAP_INDEX}] 已自动更新"
