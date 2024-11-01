#!/bin/bash
# Run this cript once the node is fully synced

# Config Chain
CHAIN="evmos" # Default is evmos
CHAINID="$CHAIN"_9000-1 # # Default is evmos_9000-1
DENOM="aevmos" # Default is aevmos = wei. Don't need to change
# UnStake amount: 1 tokens
UNSTAKE_AMOUNT="1000000000000000000$DENOM"

# Config paths
NODE_KEY="extnode0"
OPERATOR_ADDRESS=$(evmosd keys show $NODE_KEY --keyring-backend test --bech val -a)
# Main staking config is at staking block in genesis.json file. Default "unstake_time"/"unbonding_time": "1814400s" (21 days)
# The tokens will be available in your wallet after unbonding period.
echo "Un-staking transaction"
TX_OUTPUT=$(evmosd tx staking unbond $OPERATOR_ADDRESS $UNSTAKE_AMOUNT --from $NODE_KEY --keyring-backend test --gas 300000 --gas-prices 7000aevmos --yes --output json)
TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash')
echo "Transaction hash: $TX_HASH"
evmosd query wait-tx "$TX_HASH" --chain-id $CHAINID > /dev/null 2>&1
TX_STATUS=$(echo "$TX_OUTPUT" | jq -r 'if .raw_log == "" then "OK" else .raw_log end')
echo "Transaction status: $TX_STATUS"

# Check if TX_STATUS is "OK"
if [ "$TX_STATUS" == "OK" ]; then
  sleep 3
  ALL_VALIDATORS=$(evmosd query staking validators --output json)
  echo "Total validators: $(echo "$ALL_VALIDATORS" | jq '.validators | length')"
  VALIDATOR_INFO=$(echo "$ALL_VALIDATORS" | jq -r --arg addr "$OPERATOR_ADDRESS" '.validators[] | select(.operator_address == $addr)')
  # Check if the result is empty
    if [ -z "$VALIDATOR_INFO" ]; then
      echo "The validator $OPERATOR_ADDRESS is not found."
    else
      echo "Validator info: $VALIDATOR_INFO"
    fi
else
  echo "Error detected. Exit"
  exit 1
fi

# Check balance
echo "Current balance: (you have to wait for the unbonding period to get the tokens back)"
evmosd query bank balances "$(evmosd keys show $NODE_KEY --keyring-backend test -a)"

# Execute
# docker exec -it extnode0 bash "/root/.evmosd/node_unstake.sh"
