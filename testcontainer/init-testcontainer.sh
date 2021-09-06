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

cd /config && ./bin/config.sh ContainerFee 0

/bin/neofs-ir --config /config/config-ir.yaml &

while [[ -z "$(/bin/neofs-cli control healthcheck --ir -r localhost:16512 --binary-key /config/wallet.key | grep 'Health status: READY')" ]];
do
  sleep 1;
done

set -m
/bin/neofs-node --config /config/config-sn.yaml &

while [[ -z "$(/bin/neofs-cli control healthcheck -r localhost:16513 --binary-key /config/wallet-sn.key | grep 'Network status: ONLINE')" ]];
do
  ./bin/tick.sh
  sleep 5;
done

echo "aio container started"
fg
