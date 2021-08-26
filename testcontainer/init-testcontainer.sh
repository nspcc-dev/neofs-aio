#!/bin/bash

export ACC=/config/morph_chain.gz

/usr/bin/privnet-entrypoint.sh node --config-path /config --privnet &

while [[ "$(curl -s -o /dev/null -w %{http_code} localhost:30333)" != "422" ]];
do
  sleep 1;
done

/bin/neofs-ir --config /config/config-ir.yaml &

/bin/neofs-node --config /config/config-sn.yaml
