#!/bin/bash

# Address to send BTC to
ADDRESS="bcrt1ptyuq95l2strcnkt42ajg4c0cgtv4u0ek276p39ryusr4ma8y4frqwf2qnd"

# Amount to send per transaction (adjust as needed)
AMOUNT=0.001

# Array to store transaction IDs
declare -a TXIDS=()

# Send 10 transactions and store txids
for i in {1..10}; do
  TXID=$(merry rpc sendtoaddress "$ADDRESS" "$AMOUNT")
  if [ $? -eq 0 ]; then
    echo "Transaction $i sent successfully. TXID: $TXID"
    TXIDS+=("$TXID")
  else
    echo "Transaction $i failed!"
    exit 1
  fi
done

# Join all TXIDs into a JSON array
TXID_JSON=$(printf '%s\n' "${TXIDS[@]}" | jq -R . | jq -s .)

# Generate a block with the included txids
RESULT=$(merry rpc generateblock "$ADDRESS" "$TXID_JSON")

if [ $? -eq 0 ]; then
  echo "Block generated successfully!"
  echo "$RESULT"
else
  echo "Failed to generate block."
  exit 1
fi