docker compose up -d  generate_genesis

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
docker compose restart  validator_node_three
docker compose restart  validator_node_four
docker compose restart  validator_node_five
docker compose restart  validator_node_six
docker compose restart  validator_node_seven