#!/bin/bash

## When we start AIO as a separate container or part of a docker-compose. In this case we move background tasks to foreground.
## Otherwise we may use AIO container like a base for own container, thus we need just run all AIO services, before our service.
IS_PURE_START="true"
## if "true" http service will be started
IS_START_HTTP="true"
## if "true" rest service will be started
IS_START_REST="true"

while getopts d:h:r: option; do
  case $option in
    d)
      IS_PURE_START="$OPTARG"
      ;;
    h)
      IS_START_HTTP="$OPTARG"
      ;;
    r)
      IS_START_REST="$OPTARG"
      ;;
  esac
done

export ACC=/config/morph_chain.gz

/usr/bin/privnet-entrypoint.sh node --config-path /config --privnet &

while [[ "$(curl -s -o /dev/null -w %{http_code} localhost:30333)" != "422" ]];
do
  sleep 2;
done

export NEOGO=/usr/bin/neo-go
export WALLET=/config/node-wallet.json

cd /config && ./bin/config.sh ContainerFee 0 && ./bin/config.sh ContainerAliasFee 0

/usr/bin/neofs-ir --config /config/config-ir.yaml &

while [[ -z "$(/usr/bin/neofs-cli control healthcheck --ir --endpoint localhost:16512 -c /config/cli-cfg-ir.yaml | grep 'Health status: READY')" ]];
do
  sleep 2;
done

set -m
/usr/bin/neofs-node --config /config/config-sn.yaml &

while [[ -z "$(/usr/bin/neofs-cli control healthcheck --endpoint localhost:16513 -c /config/cli-cfg-sn.yaml | grep 'Network status: ONLINE')" ]];
do
  ./bin/tick.sh
  sleep 2
done

set -a

if [ $IS_START_HTTP = "true" ]; then
    . /config/http.env
    /usr/bin/neofs-http-gw &

    while [[ "$(curl -s -o /dev/null -w %{http_code} $HTTP_GW_SERVER_0_ADDRESS)" != "404" ]];
    do
      sleep 1;
    done
fi

if [ $IS_START_REST = "true" ]; then
    . /config/rest.env
    /usr/bin/neofs-rest-gw &

    while [[ "$(curl -s -o /dev/null -w %{http_code} $REST_GW_LISTEN_ADDRESS)" != "404" ]];
    do
      sleep 1;
    done
fi

echo "aio container started"

if [ $IS_PURE_START = "true" ]; then
    fg
fi
