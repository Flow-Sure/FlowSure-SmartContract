# FlowSure Smart Contracts

FlowSure provides insured on-chain actions using Flow Actions (FLIP-338) and Scheduled Transactions. This system automatically retries failed transactions and compensates users when retries are exhausted.

## 🎯 Overview

FlowSure wraps on-chain actions (token swaps, NFT mints, transfers) with automatic retry logic and insurance compensation. If an action fails, it's automatically retried. If all retries fail, users are compensated from a pooled insurance vault.

## 🧩 Architecture

### Core Contracts

1. **Events.cdc** - Event definitions for system observability
2. **InsuranceVault.cdc** - Manages pooled funds for user compensation
3. **Scheduler.cdc** - Handles retry scheduling and execution
4. **InsuredAction.cdc** - Main wrapper for executing insured actions

### Workflow

```
User Action → Execute → Success ✓
                    ↓ Failure
                Schedule Retry → Execute → Success ✓
                              ↓ Failure
                          Retry Again → Success ✓
                                    ↓ All Retries Failed
                                Compensate User 💰
```

## 🚀 Quick Start

### Prerequisites

- Flow CLI installed
- Flow testnet account with FLOW tokens

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd FlowSure-SmartContract

# Install Flow CLI
sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
```

### Deploy to Emulator

```bash
# Start emulator
flow emulator start

# Deploy contracts (in new terminal)
flow project deploy --network=emulator
```

### Deploy to Testnet

1. Update `flow.json` with your testnet credentials
2. Deploy:
```bash
flow project deploy --network=testnet
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## 📁 Project Structure

```
FlowSure-SmartContract/
├── contracts/
│   ├── Events.cdc              # Event definitions
│   ├── InsuranceVault.cdc      # Insurance pool management
│   ├── Scheduler.cdc           # Retry scheduling logic
│   └── InsuredAction.cdc       # Main action wrapper
├── transactions/
│   ├── deposit_to_vault.cdc    # Fund insurance vault
│   ├── execute_insured_action.cdc  # Execute insured action
│   └── execute_scheduled_retry.cdc # Manually trigger retry
├── scripts/
│   ├── get_vault_stats.cdc     # Query vault statistics
│   ├── get_action_record.cdc   # Get action details
│   ├── get_all_actions.cdc     # List all actions
│   ├── get_scheduled_actions.cdc # List scheduled retries
│   └── get_action_stats.cdc    # System statistics
├── flow.json                   # Flow configuration
├── DEPLOYMENT.md              # Deployment guide
└── README.md                  # This file
```

## 💡 Usage Examples

### Fund the Insurance Vault

```bash
flow transactions send ./transactions/deposit_to_vault.cdc 100.0 \
  --signer testnet-account \
  --network testnet
```

### Execute an Insured Action

```bash
# Execute a token swap (will succeed)
flow transactions send ./transactions/execute_insured_action.cdc \
  "token_swap" false 3 \
  --signer testnet-account \
  --network testnet

# Execute a failing action (will retry and compensate)
flow transactions send ./transactions/execute_insured_action.cdc \
  "nft_mint" true 3 \
  --signer testnet-account \
  --network testnet
```

### Query System State

```bash
# Get vault statistics
flow scripts execute ./scripts/get_vault_stats.cdc --network testnet

# Get action details
flow scripts execute ./scripts/get_action_record.cdc "action_1" --network testnet

# View all actions
flow scripts execute ./scripts/get_all_actions.cdc --network testnet

# Check scheduled retries
flow scripts execute ./scripts/get_scheduled_actions.cdc --network testnet

# System statistics
flow scripts execute ./scripts/get_action_stats.cdc --network testnet
```

## 🔧 Contract Details

### InsuredAction.cdc

Main contract for executing insured actions.

**Key Functions:**
- `insuredAction()` - Execute an action with insurance
- `executeScheduledRetry()` - Manually trigger a retry
- `getActionRecord()` - Get action status
- `getStats()` - Get system statistics

**Supported Actions:**
- `token_swap` - Token swaps
- `nft_mint` - NFT minting
- `token_transfer` - Token transfers

### InsuranceVault.cdc

Manages the insurance pool for compensating users.

**Key Functions:**
- `deposit()` - Add funds to vault
- `payOut()` - Compensate user (internal)
- `getVaultStats()` - Get vault statistics

### Scheduler.cdc

Handles retry scheduling and tracking.

**Key Functions:**
- `scheduleRetry()` - Schedule a retry
- `getScheduledAction()` - Get scheduled action details
- `isReadyForRetry()` - Check if action is ready

### Events.cdc

Defines all system events for observability.

**Events:**
- `TransactionStatusEvent` - Action status updates
- `CompensationEvent` - User compensation
- `RetryScheduledEvent` - Retry scheduled
- `ActionSuccessEvent` - Action succeeded
- `ActionFailureEvent` - Action failed
- `VaultDepositEvent` - Vault deposit
- `VaultPayoutEvent` - Vault payout

## 🎨 Configuration

Default settings in `InsuredAction.cdc`:
- **Retry Delay**: 60 seconds
- **Compensation Amount**: 1.0 FLOW
- **Max Retries**: Configurable per action

## 🧪 Testing

### Test Successful Action

```bash
flow transactions send ./transactions/execute_insured_action.cdc \
  "token_swap" false 3 \
  --signer testnet-account \
  --network testnet
```

### Test Failed Action with Retries

```bash
flow transactions send ./transactions/execute_insured_action.cdc \
  "token_swap" true 3 \
  --signer testnet-account \
  --network testnet
```

### Monitor Events

```bash
flow events get A.YOUR_ADDRESS.Events.TransactionStatusEvent \
  --network testnet
```

## 📊 System Statistics

View real-time statistics:
- Total actions executed
- Success rate
- Total compensations paid
- Vault balance

```bash
flow scripts execute ./scripts/get_action_stats.cdc --network testnet
flow scripts execute ./scripts/get_vault_stats.cdc --network testnet
```

## 🔐 Security Considerations

- Insurance vault requires proper funding
- Admin functions protected by resource ownership
- Retry limits prevent infinite loops
- Compensation amounts configurable

## 🛣️ Roadmap

- [ ] Integration with Forte Scheduled Transactions
- [ ] $SAFE token for stakers
- [ ] Dynamic compensation calculation
- [ ] Additional action types
- [ ] Governance mechanism
- [ ] Frontend dashboard

## 📚 Resources

- [Flow Documentation](https://developers.flow.com/)
- [Cadence Language](https://developers.flow.com/cadence/language)
- [FLIP-338: Flow Actions](https://github.com/onflow/flips)
- [Deployment Guide](./DEPLOYMENT.md)

## 🤝 Contributing

Contributions welcome! Please read the contributing guidelines before submitting PRs.

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For issues and questions:
- Open an issue on GitHub
- Check [DEPLOYMENT.md](./DEPLOYMENT.md) for troubleshooting

---

Built with ❤️ for the Flow blockchain ecosystem
