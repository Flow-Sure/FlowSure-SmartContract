# FlowSure FLOW Token Staking Guide

## Overview

FlowSure's staking system allows users to stake FLOW tokens to receive:
1. **Premium Discounts** on insurance fees (10-20%)
2. **Staking Rewards** at 5% APY
3. **Auto-Compound** functionality to maximize returns

## Key Features

### 1. Premium Discounts
- **50+ FLOW staked** → 10% discount on insurance premiums
- **100+ FLOW staked** → 20% discount on insurance premiums

### 2. Staking Rewards
- **5% Annual Percentage Yield (APY)** on staked FLOW
- Rewards calculated continuously based on staking duration
- Claim rewards anytime or auto-compound them

### 3. Auto-Compound
- Automatically claim and re-stake rewards
- Configurable compound frequency
- Maximizes compound interest effect

## Contract Architecture

### FrothRewards Contract
Main staking contract that manages:
- User staking positions (FrothStaker resource)
- Reward calculations (5% APY)
- Discount tier logic
- Total staked amount tracking

### AutoCompound Contract
Manages automatic reward compounding:
- Scheduled compound operations
- Compound frequency configuration
- Compound history tracking

## Getting Started

### 1. Setup Staker Account

First, create a FrothStaker resource in your account:

```cadence
// Transaction: create_froth_staker.cdc
import FrothRewards from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(SaveValue, BorrowValue, StorageCapabilities, Capabilities) &Account) {
        if signer.storage.borrow<&FrothRewards.FrothStaker>(from: FrothRewards.StakerStoragePath) != nil {
            log("Staker already exists")
            return
        }
        
        let staker <- FrothRewards.createStaker()
        signer.storage.save(<-staker, to: FrothRewards.StakerStoragePath)
        
        let cap = signer.capabilities.storage.issue<&FrothRewards.FrothStaker>(
            FrothRewards.StakerStoragePath
        )
        signer.capabilities.publish(cap, at: FrothRewards.StakerPublicPath)
        
        log("FrothStaker created successfully")
    }
}
```

### 2. Stake FLOW Tokens

Stake your FLOW tokens to start earning rewards and discounts:

```cadence
// Transaction: stake_froth.cdc
// Parameters: amount (UFix64) - Amount of FLOW to stake

import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewards from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let stakerRef: &FrothRewards.FrothStaker
    let flowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
        
        self.flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
    }
    
    execute {
        let tokens <- self.flowVault.withdraw(amount: amount)
        self.stakerRef.stake(from: <-tokens)
        log("Successfully staked ".concat(amount.toString()).concat(" FLOW"))
    }
}
```

### 3. Check Pending Rewards

View your accumulated rewards:

```cadence
// Script: get_pending_rewards.cdc
import FrothRewards from "../contracts/FrothRewards.cdc"

access(all) fun main(user: Address): UFix64 {
    let account = getAccount(user)
    
    if let stakerRef = account.capabilities.borrow<&{FrothRewards.StakerPublic}>(
        FrothRewards.StakerPublicPath
    ) {
        return stakerRef.calculatePendingRewards()
    }
    
    return 0.0
}
```

### 4. Claim Rewards

Claim your staking rewards to your FLOW vault:

```cadence
// Transaction: claim_rewards.cdc
import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewards from 0x8401ed4fc6788c8a

transaction {
    let stakerRef: &FrothRewards.FrothStaker
    let flowVault: &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
        
        self.flowVault = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
    }
    
    execute {
        let pendingRewards = self.stakerRef.calculatePendingRewards()
        
        if pendingRewards > 0.0 {
            let rewardTokens <- self.stakerRef.claimRewards()
            self.flowVault.deposit(from: <-rewardTokens)
            log("Successfully claimed ".concat(pendingRewards.toString()).concat(" FLOW in rewards"))
        }
    }
}
```

### 5. Unstake FLOW Tokens

Withdraw your staked FLOW tokens:

```cadence
// Transaction: unstake_froth.cdc
// Parameters: amount (UFix64) - Amount of FLOW to unstake

import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewards from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let stakerRef: &FrothRewards.FrothStaker
    let flowVault: &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
        
        self.flowVault = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
    }
    
    execute {
        let tokens <- self.stakerRef.unstake(amount: amount)
        self.flowVault.deposit(from: <-tokens)
        log("Successfully unstaked ".concat(amount.toString()).concat(" FLOW"))
    }
}
```

## Reward Calculation

Rewards are calculated using the formula:

```
rewards = stakedAmount × annualRewardRate × stakingDuration / secondsPerYear
```

Where:
- `stakedAmount`: Your staked FLOW balance
- `annualRewardRate`: 0.05 (5% APY)
- `stakingDuration`: Time elapsed since last claim (in seconds)
- `secondsPerYear`: 31,536,000 seconds

### Example

If you stake **1000 FLOW** for **30 days**:
- Staking duration: 30 days × 86,400 seconds = 2,592,000 seconds
- Rewards: 1000 × 0.05 × 2,592,000 / 31,536,000 = **4.11 FLOW**

## Important Notes

### Testnet Compatibility
- System uses FLOW tokens (native to testnet)
- No custom token deployment required
- Fully functional on Flow Testnet

### Reward Pool
- Contract admin must fund the rewards vault at `/storage/FlowSureRewardsVault`
- Ensure sufficient FLOW balance for reward payouts
- Monitor `totalRewardsPaid` to track reward distribution

### Discount Application
- Discounts apply automatically when using FlowSure insurance
- Discount tier based on current staked amount
- No additional action required after staking

### Auto-Compound
- Requires AutoCompound resource setup (separate transaction)
- Compounds rewards automatically at configured frequency
- Maximizes returns through compound interest

## Events

The staking system emits the following events:

### FrothStakedEvent
```cadence
event FrothStakedEvent(
    user: Address,
    amount: UFix64,
    totalStaked: UFix64,
    timestamp: UFix64
)
```

### FrothUnstakedEvent
```cadence
event FrothUnstakedEvent(
    user: Address,
    amount: UFix64,
    remainingStaked: UFix64,
    timestamp: UFix64
)
```

### RewardsClaimed
```cadence
event RewardsClaimed(
    user: Address,
    amount: UFix64,
    timestamp: UFix64
)
```

### PremiumDiscountAppliedEvent
```cadence
event PremiumDiscountAppliedEvent(
    user: Address,
    discount: UFix64,
    baseFee: UFix64,
    finalFee: UFix64,
    timestamp: UFix64
)
```

## Contract Addresses

### Testnet
- **FrothRewards**: `0x8401ed4fc6788c8a`
- **FungibleToken**: `0x9a0766d93b6608b7`
- **FlowToken**: `0x7e60df042a9c0868`

## Security Considerations

1. **Staked tokens are locked** in the FrothStaker resource
2. **Only the owner** can unstake or claim rewards
3. **Rewards are paid** from the contract's rewards vault
4. **Admin must maintain** sufficient FLOW in rewards vault
5. **No lock-up period** - unstake anytime

## Support

For questions or issues:
- Check transaction logs for error messages
- Verify staker resource exists before staking
- Ensure sufficient FLOW balance for transactions
- Monitor pending rewards with the script

---

**Happy Staking! 🚀**
