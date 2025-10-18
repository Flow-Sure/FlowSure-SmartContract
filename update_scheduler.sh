#!/bin/bash

# Read the contract code and encode it
CONTRACT_CODE=$(cat contracts/Scheduler.cdc)

# Update the contract on testnet
flow transactions send transactions/update_scheduler_contract.cdc \
  --args-json "[{\"type\":\"String\",\"value\":\"$CONTRACT_CODE\"}]" \
  --signer testnet-account \
  --network testnet \
  --gas-limit 9999

echo "Scheduler contract updated successfully!"
