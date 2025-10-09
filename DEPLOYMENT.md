# FlowSure Smart Contract Deployment Guide

## Prerequisites

- Flow CLI installed ([Installation Guide](https://developers.flow.com/tools/flow-cli/install))
- Flow testnet account with FLOW tokens
- Node.js (optional, for testing)

## Setup

### 1. Install Flow CLI

```bash
sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
```

### 2. Configure Testnet Account

Update `flow.json` with your testnet account details:

```json
"testnet-account": {
  "address": "YOUR_TESTNET_ADDRESS",
  "key": {
    "type": "hex",
    "index": 0,
    "signatureAlgorithm": "ECDSA_P256",
    "hashAlgorithm": "SHA3_256",
    "privateKey": "YOUR_PRIVATE_KEY"
  }
}
```

## Deployment Steps

### Option 1: Deploy to Emulator (Local Testing)

1. Start the Flow emulator:
```bash
flow emulator start
```

2. In a new terminal, deploy contracts:
```bash
flow project deploy --network=emulator
```

### Option 2: Deploy to Testnet

1. Deploy all contracts:
```bash
flow project deploy --network=testnet
```

2. Verify deployment:
```bash
flow accounts get YOUR_TESTNET_ADDRESS --network=testnet
```

## Contract Deployment Order

The contracts are deployed in the following order (automatically handled by Flow CLI):

1. **Events.cdc** - Event definitions
2. **InsuranceVault.cdc** - Pooled funds management
3. **Scheduler.cdc** - Retry scheduling
4. **InsuredAction.cdc** - Main action wrapper

## Post-Deployment Setup

### 1. Fund the Insurance Vault

```bash
flow transactions send ./transactions/deposit_to_vault.cdc 100.0 \
  --signer testnet-account \
  --network testnet
```

### 2. Verify Vault Balance

```bash
flow scripts execute ./scripts/get_vault_stats.cdc \
  --network testnet
```

## Testing the System

### 1. Execute a Successful Action

```bash
flow transactions send ./transactions/execute_insured_action.cdc \
  "token_swap" false 3 \
  --signer testnet-account \
  --network testnet
```

### 2. Execute a Failing Action (with retries)

```bash
flow transactions send ./transactions/execute_insured_action.cdc \
  "token_swap" true 3 \
  --signer testnet-account \
  --network testnet
```

### 3. Check Action Status

```bash
flow scripts execute ./scripts/get_action_record.cdc "action_1" \
  --network testnet
```

### 4. View All Actions

```bash
flow scripts execute ./scripts/get_all_actions.cdc \
  --network testnet
```

### 5. View Scheduled Retries

```bash
flow scripts execute ./scripts/get_scheduled_actions.cdc \
  --network testnet
```

### 6. Execute a Scheduled Retry

```bash
flow transactions send ./transactions/execute_scheduled_retry.cdc "action_1" \
  --signer testnet-account \
  --network testnet
```

### 7. Check System Statistics

```bash
flow scripts execute ./scripts/get_action_stats.cdc \
  --network testnet
```

## Monitoring Events

View emitted events using Flow CLI:

```bash
flow events get A.YOUR_ADDRESS.Events.TransactionStatusEvent \
  --network testnet \
  --start BLOCK_HEIGHT \
  --end BLOCK_HEIGHT
```

Available events:
- `Events.TransactionStatusEvent`
- `Events.CompensationEvent`
- `Events.RetryScheduledEvent`
- `Events.ActionSuccessEvent`
- `Events.ActionFailureEvent`
- `Events.VaultDepositEvent`
- `Events.VaultPayoutEvent`

## Troubleshooting

### Contract Import Errors

If you encounter import errors, ensure:
- All contracts are deployed in the correct order
- Contract addresses in `flow.json` are correct
- You're using the correct network (emulator/testnet)

### Insufficient Balance Errors

Ensure your testnet account has enough FLOW tokens:
```bash
flow accounts get YOUR_ADDRESS --network testnet
```

Get testnet tokens from the [Flow Faucet](https://testnet-faucet.onflow.org/).

### Transaction Failures

Check transaction details:
```bash
flow transactions get TRANSACTION_ID --network testnet
```

## Next Steps

1. Integrate with frontend application
2. Set up event listeners for real-time updates
3. Configure retry delays and compensation amounts
4. Implement additional action types
5. Add comprehensive testing suite

## Resources

- [Flow Documentation](https://developers.flow.com/)
- [Cadence Language Reference](https://developers.flow.com/cadence/language)
- [Flow CLI Reference](https://developers.flow.com/tools/flow-cli)
- [Flow Testnet Faucet](https://testnet-faucet.onflow.org/)
