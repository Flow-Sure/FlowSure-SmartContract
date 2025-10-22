# FlowSure Smart Contracts

FlowSure provides insured on-chain actions with automatic retry logic, insurance compensation, $FROTH or $FLOW token staking rewards, and Dapper NFT protection. The system automatically retries failed transactions and compensates users when retries are exhausted.

## 🎯 Overview

FlowSure wraps on-chain actions (token swaps, NFT mints, transfers, Dapper NFT operations) with automatic retry logic and insurance compensation. Users can stake $FROTH or $FLOW tokens to receive premium discounts on insurance fees. The platform also provides comprehensive protection for Dapper NFT operations including NBA Top Shot, NFL All Day, and Disney Pinnacle.

## 🧩 Architecture

### Core Contracts

1. **Events.cdc** - Event definitions for observability
2. **InsuranceVault.cdc** - Insurance pool and payouts
3. **Scheduler.cdc** - Retry scheduling and execution
4. **FrothRewardsV2.cdc** - $FROTH staking with tiered fee discounts
5. **DapperAssetProtection.cdc** - Dapper NFT insurance and protection
6. **InsuredAction.cdc** - Wrapper for insured actions and discounts
7. **ScheduledTransfer.cdc** - Scheduled transfers (deployed from scheduler account)
8. **FlowSureActions.cdc** - Shared action helpers and types
9. **AutoCompound.cdc** - Optional auto-compounding of rewards

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

Note: Uses `FlowTransactionScheduler` on testnet (`0x8c5303eaa26202d6`) as referenced in `flow.json`.

**Testnet Deployment Status:**
- Account Address: `0x8401ed4fc6788c8a`
- Network: Flow Testnet
- Status: ✅ **Successfully Deployed**

**Deployed Contracts:**
- InsuranceVault: `0x8401ed4fc6788c8a`
- Scheduler: `0x8401ed4fc6788c8a`
- FrothRewardsV2: `0x8401ed4fc6788c8a`
- DapperAssetProtection: `0x8401ed4fc6788c8a`
- InsuredAction: `0x8401ed4fc6788c8a`
- ScheduledTransfer: `0xfe1ad3a05230e532`
- Events: `0x8401ed4fc6788c8a` (legacy - events now in individual contracts)

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## 📁 Project Structure

```
FlowSure-SmartContract/
├── contracts/
│   ├── Events.cdc                    # Event definitions
│   ├── InsuranceVault.cdc            # Insurance pool management
│   ├── Scheduler.cdc                 # Retry scheduling logic
│   ├── ScheduledTransfer.cdc         # Scheduled transfer orchestration
│   ├── FrothRewardsV2.cdc            # $FROTH staking (v2)
│   ├── DapperAssetProtection.cdc     # Dapper NFT insurance
│   ├── InsuredAction.cdc             # Main action wrapper
│   ├── FlowSureActions.cdc           # Shared action helpers
│   ├── AutoCompound.cdc              # Auto-compounding (optional)
│   ├── connectors/
│   │   └── IncrementFiConnector.cdc  # DEX connector (IncrementFi)
│   └── interfaces/
│       └── IFlowSureAction.cdc       # Action interface/types
├── transactions/
│   ├── deposit_to_vault.cdc
│   ├── execute_insured_action.cdc
│   ├── execute_insured_swap_action.cdc
│   ├── execute_insured_transfer_action.cdc
│   ├── schedule_transfer.cdc
│   ├── create_scheduled_transfer_auth_v2.cdc
│   ├── execute_scheduled_transfer_v2.cdc
│   └── ...
├── scripts/
│   ├── get_vault_stats.cdc
│   ├── get_action_record.cdc
│   ├── get_all_actions.cdc
│   ├── get_scheduled_actions.cdc
│   ├── get_action_stats.cdc
│   ├── get_staker_info.cdc
│   ├── get_staking_summary.cdc
│   ├── fetch_linked_nfts.cdc
│   └── get_swap_quote.cdc
├── flow.json                         # Flow configuration
├── DEPLOYMENT.md                     # Deployment guide
└── README.md                         # This file
```

### Connectors & Interfaces

- **`contracts/connectors/IncrementFiConnector.cdc`** – DEX connector used by swap transactions.
- **`contracts/interfaces/IFlowSureAction.cdc`** – Common action interface/types for `InsuredAction.cdc` and `FlowSureActions.cdc`.

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

### Schedule a Transfer (v2)

```bash
# Create/update auth for scheduled transfers
flow transactions send ./transactions/create_scheduled_transfer_auth_v2.cdc \
  --signer testnet-account \
  --network testnet

# Schedule a transfer
flow transactions send ./transactions/schedule_transfer.cdc \
  "<recipient>" "<amount>" \
  --signer testnet-account \
  --network testnet

# Execute (scheduler account)
flow transactions send ./transactions/execute_scheduled_transfer_v2.cdc \
  "<actionId>" \
  --signer testnet-scheduler-account \
  --network testnet
```

### Execute an Insured DEX Swap

```bash
flow transactions send ./transactions/execute_insured_swap_action.cdc \
  "<pool>" "<tokenIn>" "<tokenOut>" "<amountIn>" \
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

Main contract for executing insured actions with automatic $FROTH discount application.

**Key Functions:**
- `insuredAction()` - Execute an action with insurance (discount automatically applied)
- `executeScheduledRetry()` - Manually trigger a retry
- `getActionRecord()` - Get action status
- `getInsuranceFee(user)` - Get discounted insurance fee for user
- `getStats()` - Get system statistics

**Supported Actions:**
- `token_swap` - Token swaps
- `nft_mint` - NFT minting
- `token_transfer` - Token transfers
- `dapper_nft_mint` - Dapper NFT minting
- `dapper_pack_opening` - Dapper pack opening
- `dapper_nft_transfer` - Dapper NFT transfer

**Configuration:**
- Default insurance fee: 0.5 FLOW
- Default compensation: 1.0 FLOW
- Default retry delay: 60 seconds

### FrothRewards.cdc

Manages $FROTH token staking and premium discount system.

**Key Features:**
- Stake $FROTH tokens to earn insurance discounts
- Tiered discount system: 10% (50+ FROTH) and 20% (100+ FROTH)
- Unstaking functionality
- Real-time discount calculation

**Key Functions:**
- `createStaker()` - Create staker resource
- `stake(amount)` - Stake $FROTH tokens
- `unstake(amount)` - Unstake $FROTH tokens
- `getDiscount(user)` - Get user's discount percentage
- `getStakedAmount(user)` - Get user's staked amount
- `calculateDiscountedFee(baseFee, user)` - Calculate discounted fee
- `getTotalStaked()` - Get total staked across all users
- `getTotalStakers()` - Get number of stakers

**Discount Tiers:**
- 0-49 FROTH: 0% discount
- 50-99 FROTH: 10% discount
- 100+ FROTH: 20% discount

### DapperAssetProtection.cdc

Provides insurance coverage for Dapper NFT operations with automatic retry and compensation.

**Supported Dapper Assets:**
- NBA Top Shot (Packs & Moments)
- NFL All Day (Moments)
- Disney Pinnacle (Pins)

**Action Types:**
- MINT - NFT minting protection
- PACK_OPENING / PIN_OPENING - Pack/pin opening protection
- TRANSFER - NFT transfer protection

**Key Functions:**
- `insureDapperAsset(user, assetType, assetId, actionType)` - Protect Dapper asset operation
- `getProtectedAssets(user)` - Get all protected assets for user
- `isAssetProtected(user, assetId)` - Check if asset is protected
- `removeProtection(user, assetId)` - Remove asset protection
- `getStats()` - Get protection statistics

**Protection Flow:**
- Automatic retry up to 3 times on failure
- 5.0 FLOW compensation if all retries fail
- Asset status tracking (PROTECTED → RETRY_SCHEDULED → SUCCESS/COMPENSATED)

**Configuration:**
- Default compensation: 5.0 FLOW
- Max retries: 3

### InsuranceVault.cdc

Manages the insurance pool for compensating users.

**Key Functions:**
- `deposit()` - Add funds to vault
- `payOut()` - Compensate user (internal)
- `getVaultStats()` - Get vault statistics
- `emergencyWithdraw()` - Admin emergency withdrawal

**Statistics Tracked:**
- Total pool balance
- Total deposits
- Total payouts
- Active users

### Scheduler.cdc

Handles retry scheduling and tracking.

**Key Functions:**
- `scheduleRetry()` - Schedule a retry
- `getScheduledAction()` - Get scheduled action details
- `isReadyForRetry()` - Check if action is ready
- `removeScheduledAction()` - Remove scheduled action

### Events.cdc

Defines all system events for observability.

**Core Events:**
- `TransactionStatusEvent` - Action status updates
- `CompensationEvent` - User compensation
- `RetryScheduledEvent` - Retry scheduled
- `ActionSuccessEvent` - Action succeeded
- `ActionFailureEvent` - Action failed
- `VaultDepositEvent` - Vault deposit
- `VaultPayoutEvent` - Vault payout

**FrothRewards Events:**
- `FrothStakedEvent` - User staked $FROTH
- `FrothUnstakedEvent` - User unstaked $FROTH
- `PremiumDiscountAppliedEvent` - Discount applied to insurance fee

**DapperAssetProtection Events:**
- `DapperAssetProtectedEvent` - Asset protection initiated
- `DapperAssetCompensatedEvent` - User compensated after failure
- `DapperActionSuccessEvent` - Dapper action succeeded
- `DapperActionRetryEvent` - Retry scheduled for Dapper action

## 🎨 Configuration

**InsuredAction.cdc:**
- Insurance Fee: 0.5 FLOW (before discount)
- Retry Delay: 60 seconds
- Compensation Amount: 1.0 FLOW
- Max Retries: Configurable per action

**FrothRewards.cdc:**
- Discount Tier 1: 10% at 50+ FROTH staked
- Discount Tier 2: 20% at 100+ FROTH staked

**DapperAssetProtection.cdc:**
- Compensation Amount: 5.0 FLOW
- Max Retries: 3
- Supported Assets: NBA Top Shot, NFL All Day, Disney Pinnacle

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
- Total $FROTH staked
- Number of stakers
- Total Dapper assets protected

```bash
flow scripts execute ./scripts/get_action_stats.cdc --network testnet
flow scripts execute ./scripts/get_vault_stats.cdc --network testnet
```

## 🔐 Security Considerations

- Insurance vault requires proper funding
- Admin functions protected by resource ownership
- Retry limits prevent infinite loops
- Compensation amounts configurable

## ✨ Key Features

### 💎 $FROTH Token Staking & Rewards
- Stake $FROTH tokens to earn premium discounts on insurance fees
- Tiered discount system: 10% (50+ FROTH) and 20% (100+ FROTH)
- Automatic discount application on all insured actions
- Real-time discount calculation and tracking

### 🎮 Dapper NFT Protection
- Comprehensive insurance for Dapper ecosystem NFTs
- Supports NBA Top Shot, NFL All Day, and Disney Pinnacle
- Protects mint, pack opening, and transfer operations
- Automatic retry up to 3 times on failure
- 5.0 FLOW compensation if all retries fail

### 🔄 Automatic Retry & Compensation
- Failed transactions automatically retried with configurable delays
- Users compensated from insurance pool when retries exhausted
- Configurable retry limits and compensation amounts
- Real-time action status tracking

### 📊 Comprehensive Event Tracking
- All actions emit events visible in Flow Explorer
- Track staking, unstaking, and discount applications
- Monitor Dapper asset protection and compensations
- Real-time observability for all system operations
