#!/bin/bash

# FlowSure Testing Script
# This script helps test the FlowSure smart contracts

set -e

NETWORK=${1:-emulator}
ACCOUNT=${2:-emulator-account}

echo "🧪 FlowSure Testing Script"
echo "Network: $NETWORK"
echo "Account: $ACCOUNT"
echo ""

# Function to run a script
run_script() {
    echo "📊 Running: $1"
    flow scripts execute "$1" --network="$NETWORK"
    echo ""
}

# Function to send a transaction
send_transaction() {
    echo "📤 Sending: $1"
    shift
    flow transactions send "$@" --signer="$ACCOUNT" --network="$NETWORK"
    echo ""
}

echo "=== Step 1: Check Initial Vault Stats ==="
run_script "./scripts/get_vault_stats.cdc"

echo "=== Step 2: Deposit to Vault ==="
send_transaction "Deposit 100 FLOW" "./transactions/deposit_to_vault.cdc" 100.0

echo "=== Step 3: Check Vault Stats After Deposit ==="
run_script "./scripts/get_vault_stats.cdc"

echo "=== Step 4: Execute Successful Action ==="
send_transaction "Execute successful token swap" "./transactions/execute_insured_action.cdc" "token_swap" false 3

echo "=== Step 5: Execute Failing Action ==="
send_transaction "Execute failing NFT mint" "./transactions/execute_insured_action.cdc" "nft_mint" true 3

echo "=== Step 6: Check All Actions ==="
run_script "./scripts/get_all_actions.cdc"

echo "=== Step 7: Check Scheduled Actions ==="
run_script "./scripts/get_scheduled_actions.cdc"

echo "=== Step 8: Check System Statistics ==="
run_script "./scripts/get_action_stats.cdc"

echo "=== Step 9: Final Vault Stats ==="
run_script "./scripts/get_vault_stats.cdc"

echo "✅ Testing Complete!"
echo ""
echo "To manually execute a scheduled retry, run:"
echo "flow transactions send ./transactions/execute_scheduled_retry.cdc \"action_2\" --signer=$ACCOUNT --network=$NETWORK"
