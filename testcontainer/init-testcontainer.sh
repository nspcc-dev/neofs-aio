#!/bin/bash

export ACC=/config/morph_chain.gz

/usr/bin/privnet-entrypoint.sh node --config-path /config --privnet &

while [[ "$(curl -s -o /dev/null -w %{http_code} localhost:30333)" != "422" ]];
do
  sleep 1;
done

export NEOGO=/usr/bin/neo-go
export WALLET=/config/node-wallet.json
export WALLET_IMG=/config/node-wallet.json

cd /config && ./bin/config.sh ContainerFee 0 && ./bin/config.sh ContainerAliasFee 0

/bin/neofs-ir --config /config/config-ir.yaml &

while [[ -z "$(/bin/neofs-cli control healthcheck --ir --endpoint localhost:16512 -c /config/cli-cfg-ir.yaml | grep 'Health status: READY')" ]];
do
  sleep 1;
done

set -m
/bin/neofs-node --config /config/config-sn.yaml &

while [[ -z "$(/bin/neofs-cli control healthcheck --endpoint localhost:16513 -c /config/cli-cfg-sn.yaml | grep 'Network status: ONLINE')" ]];
do
  ./bin/tick.sh
  sleep 5;
done

echo "aio container started"
fg
