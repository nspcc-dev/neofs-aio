#!/usr/bin/env bash

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it morph neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-./morph/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-config/node-wallet.json}"

# Netmap contract address resolved by NNS
NETMAP_ADDR=`./bin/resolve.sh netmap.neofs`

# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[2].address`

# Fetch current epoch value
EPOCH=`${NEOGO} contract testinvokefunction -r \
http://localhost:30333 \
${NETMAP_ADDR} \
epoch | grep 'value' | awk -F'"' '{ print $4 }'`

echo "Updating NeoFS epoch to $((EPOCH+1))"
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://localhost:30333 \
${NETMAP_ADDR} \
newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global
