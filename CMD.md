#### 启动命令
```shell
docker compose up -d generate_genesis
docker logs -f generate_genesis


docker compose up -d validator_node_one
docker logs -f validator_node_one
tail -50f app/node/


docker compose restart validator_node_one

docker compose down



$BIN_DIR/tf --rpc http://127.0.0.1:8545 \
--prk f9b80c203f15ca0c1ede3107c7866223b7f5730d21bf4863189b2ec31064ae2f \
--to 0x6db9cf1788d292b349bf47d9c6578c1b0f881513 \
--amount 21000


```