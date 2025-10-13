# FlowSure Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Fund Insurance Vault (Required)

```bash
flow transactions send ./transactions/deposit_to_vault.cdc 100.0 \
  --signer testnet-account \
  --network testnet
```

---

### Step 2: Test $FROTH Staking

#### 2.1 Create Staker
```bash
flow transactions send ./transactions/create_froth_staker.cdc \
  --signer testnet-account \
  --network testnet
```

#### 2.2 Stake 100 FROTH (for 20% discount)
```bash
flow transactions send ./transactions/stake_froth.cdc 100.0 \
  --signer testnet-account \
  --network testnet
```

#### 2.3 Check Your Discount
```bash
flow scripts execute ./scripts/get_staker_info.cdc 0x8401ed4fc6788c8a \
  --network testnet
```

**Expected:** 20% discount (100 FROTH staked)

---

### Step 3: Test Dapper NFT Protection

#### 3.1 Create Protection Manager
```bash
flow transactions send ./transactions/create_protection_manager.cdc \
  --signer testnet-account \
  --network testnet
```

#### 3.2 Protect NBA Top Shot NFT
```bash
flow transactions send ./transactions/protect_dapper_nft.cdc \
  "nba_topshot" 12345 "mint" \
  --signer testnet-account \
  --network testnet
```

#### 3.3 View Protected Assets
```bash
flow scripts execute ./scripts/get_protected_assets.cdc 0x8401ed4fc6788c8a \
  --network testnet
```

---

## 📋 All Commands at a Glance

### Transactions

| Action | Command |
|--------|---------|
| **Fund Vault** | `flow transactions send ./transactions/deposit_to_vault.cdc 100.0 --signer testnet-account --network testnet` |
| **Create Staker** | `flow transactions send ./transactions/create_froth_staker.cdc --signer testnet-account --network testnet` |
| **Stake FROTH** | `flow transactions send ./transactions/stake_froth.cdc 100.0 --signer testnet-account --network testnet` |
| **Unstake FROTH** | `flow transactions send ./transactions/unstake_froth.cdc 25.0 --signer testnet-account --network testnet` |
| **Create Protection** | `flow transactions send ./transactions/create_protection_manager.cdc --signer testnet-account --network testnet` |
| **Protect NFT** | `flow transactions send ./transactions/protect_dapper_nft.cdc "nba_topshot" 12345 "mint" --signer testnet-account --network testnet` |

### Scripts (Queries)

| Query | Command |
|-------|---------|
| **Vault Stats** | `flow scripts execute ./scripts/get_vault_stats.cdc --network testnet` |
| **Staker Info** | `flow scripts execute ./scripts/get_staker_info.cdc 0x8401ed4fc6788c8a --network testnet` |
| **Protected Assets** | `flow scripts execute ./scripts/get_protected_assets.cdc 0x8401ed4fc6788c8a --network testnet` |
| **Action Record** | `flow scripts execute ./scripts/get_action_record.cdc "action_id" --network testnet` |

---

## 💡 Key Information

### Contract Address
All contracts deployed at: **`0x8401ed4fc6788c8a`**

### Discount Tiers
- **50-99 FROTH:** 10% discount
- **100+ FROTH:** 20% discount

### Supported Dapper NFTs
- `nba_topshot` - NBA Top Shot
- `nfl_allday` - NFL All Day
- `disney_pinnacle` - Disney Pinnacle

### Action Types
- `mint` - NFT minting
- `pack_opening` - Pack opening
- `transfer` - NFT transfer

### Protection Features
- **Max Retries:** 3 attempts
- **Compensation:** 5.0 FLOW on failure

---

## 🎯 One-Line Test Suite

Run all tests at once:

```bash
# Setup
flow transactions send ./transactions/deposit_to_vault.cdc 100.0 --signer testnet-account --network testnet && \
flow transactions send ./transactions/create_froth_staker.cdc --signer testnet-account --network testnet && \
flow transactions send ./transactions/stake_froth.cdc 100.0 --signer testnet-account --network testnet && \
flow transactions send ./transactions/create_protection_manager.cdc --signer testnet-account --network testnet && \
flow transactions send ./transactions/protect_dapper_nft.cdc "nba_topshot" 12345 "mint" --signer testnet-account --network testnet

# Verify
flow scripts execute ./scripts/get_vault_stats.cdc --network testnet && \
flow scripts execute ./scripts/get_staker_info.cdc 0x8401ed4fc6788c8a --network testnet && \
flow scripts execute ./scripts/get_protected_assets.cdc 0x8401ed4fc6788c8a --network testnet
```

---

## 📚 Documentation

- **Full Testing Guide:** [TESTING_GUIDE.md](./TESTING_GUIDE.md)
- **Deployment Details:** [DEPLOYMENT_SUCCESS.md](./DEPLOYMENT_SUCCESS.md)
- **Complete README:** [README.md](./README.md)

---

## ✅ Success Checklist

- [ ] Vault funded with 100 FLOW
- [ ] Staker created
- [ ] 100 FROTH staked (20% discount)
- [ ] Protection manager created
- [ ] NBA Top Shot NFT protected
- [ ] All queries return data

**All done? You're ready to integrate with your frontend! 🎉**
