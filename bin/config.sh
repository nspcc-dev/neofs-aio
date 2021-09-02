#!/usr/bin/env bash

NEOFS_IR_CONTRACTS_NETMAP='6b5a4b75ed4540d14420a7c3264bb936cb78a2d4'

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it morph neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-./morph/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-config/node-wallet.json}"

# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"

# NeoFS configuration record: key is a string and value is an int
KEY=${1}
VALUE="${2}"

[ -z "$KEY" ] && echo "Empty config key" && exit 1
[ -z "$VALUE" ] && echo "Empty config value" && exit 1

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[2].address`

# Change config value in side chain
echo "Changing ${KEY} configration value to ${VALUE}"
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://localhost:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
setConfig bytes:beefcafe \
string:${KEY} \
int:${VALUE} -- ${ADDR} || exit 1

# Update epoch to apply new configuration value
./bin/tick.sh
