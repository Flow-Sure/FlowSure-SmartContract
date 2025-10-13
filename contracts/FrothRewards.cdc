access(all) contract FrothRewards {
    
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
    
    access(all) let StakerStoragePath: StoragePath
    access(all) let StakerPublicPath: PublicPath
    
    access(all) var totalStaked: UFix64
    access(all) var totalStakers: UInt64
    
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
    }
    
    access(all) resource FrothStaker: StakerPublic {
        access(all) var stakedAmount: UFix64
        access(all) var stakedAt: UFix64
        
        access(all) fun stake(amount: UFix64) {
            pre {
                amount > 0.0: "Stake amount must be greater than 0"
            }
            
            let previousAmount = self.stakedAmount
            self.stakedAmount = self.stakedAmount + amount
            
            if previousAmount == 0.0 {
                self.stakedAt = getCurrentBlock().timestamp
                FrothRewards.totalStakers = FrothRewards.totalStakers + 1
            }
            
            FrothRewards.totalStaked = FrothRewards.totalStaked + amount
            
            emit FrothStakedEvent(
                user: self.owner?.address ?? panic("No owner"),
                amount: amount,
                totalStaked: self.stakedAmount,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun unstake(amount: UFix64) {
            pre {
                amount > 0.0: "Unstake amount must be greater than 0"
                amount <= self.stakedAmount: "Insufficient staked balance"
            }
            
            self.stakedAmount = self.stakedAmount - amount
            FrothRewards.totalStaked = FrothRewards.totalStaked - amount
            
            if self.stakedAmount == 0.0 {
                FrothRewards.totalStakers = FrothRewards.totalStakers - 1
            }
            
            emit FrothUnstakedEvent(
                user: self.owner?.address ?? panic("No owner"),
                amount: amount,
                remainingStaked: self.stakedAmount,
                timestamp: getCurrentBlock().timestamp
            )
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
        
        init() {
            self.stakedAmount = 0.0
            self.stakedAt = 0.0
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
        self.StakerStoragePath = /storage/FlowSureFrothStaker
        self.StakerPublicPath = /public/FlowSureFrothStaker
        
        self.totalStaked = 0.0
        self.totalStakers = 0
    }
}
