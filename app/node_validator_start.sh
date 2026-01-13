#!/usr/bin/env bash
set -e

BASE_DIR=${BASE_DIR:-"/data/chain"}
BIN_DIR=${BIN_DIR:-"/data/chain/bin"}
KEYS_DIR=${KEYS_DIR:-"/data/app/keys"}
DATA_DIR=${DATA_DIR:-"/data/app/node"}
HTTP_PORT=${HTTP_PORT:-8545}
WS_PORT=${WS_PORT:-8546}
DB_ENGINE=${DB_ENGINE:-leveldb}
GC_MODE=${GC_MODE:-full}
MINER_GAS_PRICE=${MINER_GAS_PRICE:-1000000000}
MINER_GAS_LIMIT=${MINER_GAS_LIMIT:-35000000}
RPC_URL=${RPC_URL:-"http://127.0.0.1:8545"}
HTTP_API=${HTTP_API:-"eth,net,web3,debug,txpool,trace"}
WS_API=${WS_API:-"eth,net,web3,debug,txpool,trace"}
METRICS_PORT=${METRICS_PORT:-6060}
PPROF_PORT=${PPROF_PORT:-7060}
STAKE_AMOUNT="20001"
#RPC_URL="http://127.0.0.1:8545"


echo "=============================="
echo "  Validator Startup Script"
echo "=============================="

# check keys
if [ -f "${KEYS_DIR}/password.txt" ]; then
  echo "密钥目录已存在：$KEYS_DIR"
  echo "已初始化过，跳过密钥生成。"
else
    source $BASE_DIR/node_generate_key.sh
fi

if [ -d "$DATA_DIR" ]; then
    echo "初始化目录已存在，禁止重复初始化：$INIT_DIR"
else
    echo "开始初始化网络..."
    mkdir -p "${DATA_DIR}/geth"
    cp "${KEYS_DIR}/nodekey" "${DATA_DIR}/geth/nodekey"

    $BIN_DIR/geth init \
    --datadir "${DATA_DIR}" \
    --state.scheme hash \
    "${BASE_DIR}/config/genesis.json" > "$DATA_DIR/init.log" 2>&1
fi

cp -r $KEYS_DIR/bls/bls $DATA_DIR/
cp $KEYS_DIR/password.txt $DATA_DIR/
cp -r $KEYS_DIR/validator/keystore $DATA_DIR/
cp $BASE_DIR/config/config.toml $DATA_DIR/
cp $BASE_DIR/config/genesis.json $DATA_DIR/

if [ "$VALIDATOR_ADDR" = "001" ]; then
  RIALTO_HASH=$(grep "Successfully wrote genesis state" "${DATA_DIR}/init.log" | awk -F"hash=" '{print $2}')
  echo "提取的哈希值为: $RIALTO_HASH"
fi

DESC="Val${VALIDATOR_INDEX}"

#######################################
# 4. 检查是否已注册 StakeHub
#######################################
echo "==> Checking validator registration..."


CONS_ADDR_RAW=$($BIN_DIR/bootnode -nodekey ${KEYS_DIR}/nodekey -writeaddress)
CONS_ADDR="0x${CONS_ADDR_RAW: -40}"
echo "CONS_ADDR = $CONS_ADDR"

KEYFILE=$(ls $KEYS_DIR/validator/keystore | head -n1)
VALIDATOR_ADDR="0x${KEYFILE##*--}"
echo "VALIDATOR_ADDR = $VALIDATOR_ADDR"

if [ "$VALIDATOR_INDEX" == "001" ]; then
  echo "validator address: ${VALIDATOR_ADDR}"
    echo "HTTP: ${HTTP_PORT}, WS: ${WS_PORT}"
    echo "validator address: ${VALIDATOR_ADDR}"
    echo "HTTP: ${HTTP_PORT}, WS: ${WS_PORT}"
    cd $DATA_DIR &&  $BIN_DIR/geth \
      --config ${DATA_DIR}/config.toml \
      --datadir "${DATA_DIR}" \
      --port "${P2P_PORT}" \
      --nodekey ${DATA_DIR}/geth/nodekey \
      --password ${DATA_DIR}/password.txt \
      --unlock ${VALIDATOR_ADDR} \
      --blspassword ${DATA_DIR}/password.txt \
      --mine --miner.etherbase ${VALIDATOR_ADDR} --vote \
      --db.engine ${DB_ENGINE} \
      --gcmode ${GC_MODE} \
      --miner.gasprice ${MINER_GAS_PRICE} \
      --miner.gaslimit ${MINER_GAS_LIMIT} \
      --http --http.addr 0.0.0.0 --http.port ${HTTP_PORT} --http.api "${HTTP_API}" \
      --ws --ws.addr 0.0.0.0 --ws.port ${WS_PORT} --ws.api "${WS_API}" \
      --metrics --metrics.addr 0.0.0.0 --metrics.port ${METRICS_PORT} --metrics.expensive \
      --pprof --pprof.addr 0.0.0.0 --pprof.port ${PPROF_PORT} \
      --rialtohash ${RIALTO_HASH} \
      --rpc.allow-unprotected-txs \
      --rpc.txfeecap 1000 \
      --allow-insecure-unlock \
      --override.passedforktime 0 \
      --override.lorentz 0 \
      --override.maxwell 0 \
      --ipcpath /tmp/geth.ipc \
      --log.format terminal \
      --log.rotate \
      --log.maxsize 100 \
      --log.maxage 7 \
      --log.compress &
#    cd $DATA_DIR &&  $BIN_DIR/geth \
#      --config ${DATA_DIR}/config.toml \
#      --datadir "${DATA_DIR}" \
#      --port "${P2P_PORT}" \
#      --nodekey ${DATA_DIR}/geth/nodekey \
#      --password ${DATA_DIR}/password.txt \
#      --unlock ${VALIDATOR_ADDR} \
#      --blspassword ${DATA_DIR}/password.txt \
#      --db.engine ${DB_ENGINE} \
#      --gcmode ${GC_MODE} \
#      --mine --miner.etherbase ${VALIDATOR_ADDR} --vote \
#      --miner.gasprice ${MINER_GAS_PRICE} \
#      --miner.gaslimit ${MINER_GAS_LIMIT} \
#      --http --http.addr 0.0.0.0 --http.port ${HTTP_PORT} --http.api "${HTTP_API}" \
#      --ws --ws.addr 0.0.0.0 --ws.port ${WS_PORT} --ws.api "${WS_API}" \
#      --metrics --metrics.addr 0.0.0.0 --metrics.port ${METRICS_PORT} --metrics.expensive \
#      --pprof --pprof.addr 0.0.0.0 --pprof.port ${PPROF_PORT} \
#      --rialtohash ${RIALTO_HASH} \
#      --rpc.allow-unprotected-txs \
#      --rpc.txfeecap 1000 \
#      --allow-insecure-unlock \
#      --override.passedforktime 0 \
#      --override.lorentz 0 \
#      --override.maxwell 0 \
#      --ipcpath /tmp/geth.ipc \
#      --log.format terminal \
#      --log.rotate \
#      --log.maxsize 100 \
#      --log.maxage 7 \
#      --log.compress &
else
    echo "==> Starting validator node..."
    echo "Address: ${VALIDATOR_ADDR}"
    echo "HTTP: ${HTTP_PORT}, WS: ${WS_PORT}"
    cd $DATA_DIR &&  $BIN_DIR/geth \
      --config ${DATA_DIR}/config.toml \
      --datadir "${DATA_DIR}" \
      --port "${P2P_PORT}" \
      --bootnodes "${ENODE_URL}" \
      --http --http.addr 0.0.0.0 --http.port ${HTTP_PORT} --http.api "${HTTP_API}" \
      --ws --ws.addr 0.0.0.0 --ws.port ${WS_PORT} --ws.api "${WS_API}" \
      --syncmode full \
      --gcmode archive \
      --ipcpath /tmp/geth.ipc \
      --log.format terminal \
      --log.rotate \
      --log.maxsize 100 \
      --log.maxage 7 \
      --log.compress &
#    cd $DATA_DIR &&  $BIN_DIR/geth \
#      --config ${DATA_DIR}/config.toml \
#      --datadir "${DATA_DIR}" \
#      --port "${P2P_PORT}" \
#      --bootnodes "${ENODE_URL}" \
#      --nodekey ${DATA_DIR}/geth/nodekey \
#      --password ${DATA_DIR}/password.txt \
#      --unlock ${VALIDATOR_ADDR} \
#      --blspassword ${DATA_DIR}/password.txt \
#      --db.engine ${DB_ENGINE} \
#      --gcmode ${GC_MODE} \
#      --miner.gasprice ${MINER_GAS_PRICE} \
#      --miner.gaslimit ${MINER_GAS_LIMIT} \
#      --http --http.addr 0.0.0.0 --http.port ${HTTP_PORT} --http.api "${HTTP_API}" \
#      --ws --ws.addr 0.0.0.0 --ws.port ${WS_PORT} --ws.api "${WS_API}" \
#      --metrics --metrics.addr 0.0.0.0 --metrics.port ${METRICS_PORT} --metrics.expensive \
#      --pprof --pprof.addr 0.0.0.0 --pprof.port ${PPROF_PORT} \
#      --rialtohash ${RIALTO_HASH} \
#      --rpc.allow-unprotected-txs \
#      --rpc.txfeecap 1000 \
#      --allow-insecure-unlock \
#      --override.passedforktime 0 \
#      --override.lorentz 0 \
#      --override.maxwell 0 \
#      --ipcpath /tmp/geth.ipc \
#      --log.format terminal \
#      --log.rotate \
#      --log.maxsize 100 \
#      --log.maxage 7 \
#      --log.compress &
fi

function register_stakehub_single(){
    echo "==> Waiting for chain to be ready..."

    sleep 45  # 等待链启动 RPC ready



    echo "==> Waiting for validator ${VALIDATOR_ADDR} to receive funds..."
    echo "    RPC URL: http://127.0.0.1:8545"
    echo "    Description: $DESC"

    # 等待充值
    while true; do
        # 查询余额（返回 16 进制 Wei 单位）
        response=$(curl -s --max-time 10 -X POST http://127.0.0.1:8545 \
            -H "Content-Type: application/json" \
            -d '{
                "jsonrpc": "2.0",
                "method": "eth_getBalance",
                "params": ["'${VALIDATOR_ADDR}'", "latest"],
                "id": 1
            }' 2>/dev/null)

        # 检查 curl 是否成功
        if [ $? -ne 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - RPC 连接失败，等待重试..."
            sleep 5
            continue
        fi

        # 检查响应是否有效
        if [ -z "$response" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 空的 RPC 响应"
            sleep 5
            continue
        fi

        # 提取 16 进制余额（使用 grep 和 cut）
        hex_balance=$(echo "$response" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

        # 或者使用 jq（如果可用）
        # hex_balance=$(echo "$response" | jq -r '.result' 2>/dev/null)

        # 简单的判断：只要 hex_balance 不为空且不等于 "0x0" 就认为有余额
        if [ -n "$hex_balance" ] && [ "$hex_balance" != "0x0" ] && [ "$hex_balance" != "0x" ]; then
            echo "检测到余额！"
            echo "余额 (十六进制): $hex_balance"

            # 跳出循环，继续执行注册逻辑
            break
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S') - 余额: ${hex_balance:-0x0}，继续等待..."
        sleep 5
    done
    sleep 5 # 余额到账后再等5秒，确保链稳定
    echo "==> Validator not registered. Registering and staking..."
    echo $RPC_URL
    echo $DESC
    TX=$(${BIN_DIR}/create-validator \
                --consensus-key-dir "${DATA_DIR}" \
                --vote-key-dir "${DATA_DIR}" \
                --password-path "${DATA_DIR}/password.txt" \
                --amount ${STAKE_AMOUNT} \
                --validator-desc "${DESC}" \
            --rpc-url $RPC_URL)
    echo "${TX}"
    echo "StakeHub registration and staking check complete."
    if [ "$VALIDATOR_INDEX" != "001" ]; then
      # 如果是新增验证节点，重亲启动挖矿
          echo "==> 启动挖矿..."
          pkill -f "geth"
          sleep 5
          echo "validator address: ${VALIDATOR_ADDR}"
          echo "HTTP: ${HTTP_PORT}, WS: ${WS_PORT}"

          echo "validator address: ${VALIDATOR_ADDR}"
          echo "HTTP: ${HTTP_PORT}, WS: ${WS_PORT}"
          cd $DATA_DIR &&  $BIN_DIR/geth \
            --config ${DATA_DIR}/config.toml \
            --datadir "${DATA_DIR}" \
            --port "${P2P_PORT}" \
            --nodekey ${DATA_DIR}/geth/nodekey \
            --password ${DATA_DIR}/password.txt \
            --unlock ${VALIDATOR_ADDR} \
            --blspassword ${DATA_DIR}/password.txt \
            --db.engine ${DB_ENGINE} \
            --gcmode ${GC_MODE} \
            --mine --miner.etherbase ${VALIDATOR_ADDR} --vote \
            --miner.gasprice ${MINER_GAS_PRICE} \
            --miner.gaslimit ${MINER_GAS_LIMIT} \
            --http --http.addr 0.0.0.0 --http.port ${HTTP_PORT} --http.api "${HTTP_API}" \
            --ws --ws.addr 0.0.0.0 --ws.port ${WS_PORT} --ws.api "${WS_API}" \
            --metrics --metrics.addr 0.0.0.0 --metrics.port ${METRICS_PORT} --metrics.expensive \
            --pprof --pprof.addr 0.0.0.0 --pprof.port ${PPROF_PORT} \
            --rialtohash ${RIALTO_HASH} \
            --rpc.allow-unprotected-txs \
            --rpc.txfeecap 1000 \
            --allow-insecure-unlock \
            --override.passedforktime 0 \
            --override.lorentz 0 \
            --override.maxwell 0 \
            --ipcpath /tmp/geth.ipc \
            --log.format terminal \
            --log.rotate \
            --log.maxsize 100 \
            --log.maxage 7 \
            --log.compress &
    fi

}


# Check if registered
REGISTER_FLAG="${DATA_DIR}/stake_registered"
if [ -f "${REGISTER_FLAG}" ]; then
    echo "==> StakeHub 已注册，跳过"
else
    echo "==> 首次启动，执行 register"

    # Once geth is running, register the validator
#    register_stakehub_single

    # Mark as registered
    echo "registered:true" > "${REGISTER_FLAG}"
    echo "==> 已标记为已注册: ${REGISTER_FLAG}"

fi

tail -f /dev/null



