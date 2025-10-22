import FungibleToken from "FungibleToken"
import FlowToken from "FlowToken"

access(all) contract FrothRewardsV2 {
    
    access(all) event FrothStakedEvent(
        user: Address,
        amount: UFix64,
        totalStaked: UFix64,
        timestamp: UFix64
    )
    
    access(all) event FrothUnstakedEvent(
        user: Address,
        amount: UFix64,
        remainingStaked: UFix64,
        timestamp: UFix64
    )
    
    access(all) event PremiumDiscountAppliedEvent(
        user: Address,
        discount: UFix64,
        baseFee: UFix64,
        finalFee: UFix64,
        timestamp: UFix64
    )
    
    access(all) event RewardsClaimed(
        user: Address,
        amount: UFix64,
        timestamp: UFix64
    )
    
    access(all) let StakerStoragePath: StoragePath
    access(all) let StakerPublicPath: PublicPath
    access(all) let StakingVaultStoragePath: StoragePath
    access(all) let RewardsVaultStoragePath: StoragePath
    
    access(all) var totalStaked: UFix64
    access(all) var totalStakers: UInt64
    access(all) var annualRewardRate: UFix64
    access(all) var totalRewardsPaid: UFix64
    
    access(all) struct StakerData {
        access(all) let address: Address
        access(all) let stakedAmount: UFix64
        access(all) let discount: UFix64
        access(all) let stakedAt: UFix64
        
        init(address: Address, stakedAmount: UFix64, discount: UFix64, stakedAt: UFix64) {
            self.address = address
            self.stakedAmount = stakedAmount
            self.discount = discount
            self.stakedAt = stakedAt
        }
    }
    
    access(all) resource interface StakerPublic {
        access(all) fun getStakedAmount(): UFix64
        access(all) fun getDiscount(): UFix64
        access(all) fun getStakerData(): StakerData
        access(all) fun calculatePendingRewards(): UFix64
    }
    
    access(all) resource FrothStaker: StakerPublic {
        access(all) var stakedAmount: UFix64
        access(all) var stakedAt: UFix64
        access(self) let stakingVault: @FlowToken.Vault
        
        access(all) fun stake(from: @{FungibleToken.Vault}) {
            pre {
                from.balance > 0.0: "Stake amount must be greater than 0"
            }
            
            let amount = from.balance
            let previousAmount = self.stakedAmount
            self.stakedAmount = self.stakedAmount + amount
            
            self.stakingVault.deposit(from: <-from)
            
            if previousAmount == 0.0 {
                self.stakedAt = getCurrentBlock().timestamp
                FrothRewardsV2.totalStakers = FrothRewardsV2.totalStakers + 1
            }
            
            FrothRewardsV2.totalStaked = FrothRewardsV2.totalStaked + amount
            
            emit FrothStakedEvent(
                user: self.owner?.address ?? panic("No owner"),
                amount: amount,
                totalStaked: self.stakedAmount,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun unstake(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                amount > 0.0: "Unstake amount must be greater than 0"
                amount <= self.stakedAmount: "Insufficient staked balance"
            }
            
            self.stakedAmount = self.stakedAmount - amount
            FrothRewardsV2.totalStaked = FrothRewardsV2.totalStaked - amount
            
            if self.stakedAmount == 0.0 {
                FrothRewardsV2.totalStakers = FrothRewardsV2.totalStakers - 1
            }
            
            emit FrothUnstakedEvent(
                user: self.owner?.address ?? panic("No owner"),
                amount: amount,
                remainingStaked: self.stakedAmount,
                timestamp: getCurrentBlock().timestamp
            )
            
            return <- self.stakingVault.withdraw(amount: amount)
        }
        
        access(all) fun getDiscount(): UFix64 {
            if self.stakedAmount >= 100.0 {
                return 0.20
            } else if self.stakedAmount >= 50.0 {
                return 0.10
            }
            return 0.0
        }
        
        access(all) fun getStakedAmount(): UFix64 {
            return self.stakedAmount
        }
        
        access(all) fun getStakerData(): StakerData {
            return StakerData(
                address: self.owner?.address ?? panic("No owner"),
                stakedAmount: self.stakedAmount,
                discount: self.getDiscount(),
                stakedAt: self.stakedAt
            )
        }
        
        access(all) fun calculatePendingRewards(): UFix64 {
            if self.stakedAmount == 0.0 || self.stakedAt == 0.0 {
                return 0.0
            }
            
            let currentTime = getCurrentBlock().timestamp
            let stakingDuration = currentTime - self.stakedAt
            let secondsPerYear: UFix64 = 31536000.0
            
            let rewards = self.stakedAmount * FrothRewardsV2.annualRewardRate * stakingDuration / secondsPerYear
            return rewards
        }
        
        access(all) fun claimRewards(): @{FungibleToken.Vault} {
            let rewardAmount = self.calculatePendingRewards()
            assert(rewardAmount > 0.0, message: "No rewards to claim")
            
            self.stakedAt = getCurrentBlock().timestamp
            FrothRewardsV2.totalRewardsPaid = FrothRewardsV2.totalRewardsPaid + rewardAmount
            
            let rewardsVault = FrothRewardsV2.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: FrothRewardsV2.RewardsVaultStoragePath
            ) ?? panic("Could not borrow rewards vault")
            
            emit RewardsClaimed(
                user: self.owner?.address ?? panic("No owner"),
                amount: rewardAmount,
                timestamp: getCurrentBlock().timestamp
            )
            
            return <- rewardsVault.withdraw(amount: rewardAmount)
        }
        
        init() {
            self.stakedAmount = 0.0
            self.stakedAt = 0.0
            self.stakingVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
        }
    }
    
    access(all) fun createStaker(): @FrothStaker {
        return <- create FrothStaker()
    }
    
    access(all) fun getDiscount(user: Address): UFix64 {
        let account = getAccount(user)
        
        if let stakerRef = account.capabilities.borrow<&{StakerPublic}>(self.StakerPublicPath) {
            return stakerRef.getDiscount()
        }
        
        return 0.0
    }
    
    access(all) fun getStakedAmount(user: Address): UFix64 {
        let account = getAccount(user)
        
        if let stakerRef = account.capabilities.borrow<&{StakerPublic}>(self.StakerPublicPath) {
            return stakerRef.getStakedAmount()
        }
        
        return 0.0
    }
    
    access(all) fun getStakerData(user: Address): StakerData? {
        let account = getAccount(user)
        
        if let stakerRef = account.capabilities.borrow<&{StakerPublic}>(self.StakerPublicPath) {
            return stakerRef.getStakerData()
        }
        
        return nil
    }
    
    access(all) fun calculateDiscountedFee(baseFee: UFix64, user: Address): UFix64 {
        let discount = self.getDiscount(user: user)
        let finalFee = baseFee * (1.0 - discount)
        
        if discount > 0.0 {
            emit PremiumDiscountAppliedEvent(
                user: user,
                discount: discount,
                baseFee: baseFee,
                finalFee: finalFee,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        return finalFee
    }
    
    access(all) fun getTotalStaked(): UFix64 {
        return self.totalStaked
    }
    
    access(all) fun getTotalStakers(): UInt64 {
        return self.totalStakers
    }
    
    init() {
        self.StakerStoragePath = /storage/FlowSureFrothStakerV2
        self.StakerPublicPath = /public/FlowSureFrothStakerV2
        self.StakingVaultStoragePath = /storage/FlowSureStakingVaultV2
        self.RewardsVaultStoragePath = /storage/FlowSureRewardsVaultV2
        
        self.totalStaked = 0.0
        self.totalStakers = 0
        self.annualRewardRate = 0.05
        self.totalRewardsPaid = 0.0
    }
}
