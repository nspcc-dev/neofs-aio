#!/usr/bin/env bash

NEOFS_IR_CONTRACTS_NETMAP='6b5a4b75ed4540d14420a7c3264bb936cb78a2d4'

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it morph neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-./morph/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-config/node-wallet.json}"

# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[2].address`

# Fetch current epoch value
EPOCH=`${NEOGO} contract testinvokefunction -r \
http://localhost:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
epoch | grep 'value' | awk -F'"' '{ print $4 }'`

echo "Updating NeoFS epoch to $((EPOCH+1))"
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://localhost:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global
