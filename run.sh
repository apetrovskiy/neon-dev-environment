#!/bin/bash

RUN_NAME=$1

if [ -z "$RUN_NAME" ]; then
  echo "Usage ./run.sh <RUN_NAME>"
  exit 1
fi

mkdir -p ./test-logs/$RUN_NAME

docker-compose up neon-tracer-test

docker logs neon-tracer > ./test-logs/$RUN_NAME/neon-tracer.log 2>&1
docker logs neon-tracer-test > ./test-logs/$RUN_NAME/neon-tracer-test.log 2>&1
docker logs proxy > ./test-logs/$RUN_NAME/proxy.log 2>&1
docker logs validator > ./test-logs/$RUN_NAME/validator.log 2>&1
docker logs tracer_db > ./test-logs/$RUN_NAME/tracer_db.log 2>&1

docker-compose down
