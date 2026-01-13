#### 启动命令
```shell
docker compose up -d generate_genesis
docker logs -f generate_genesis


docker compose up -d validator_node_one
docker logs -f validator_node_one
tail -50f app/node/


docker compose restart validator_node_one

docker compose down





```