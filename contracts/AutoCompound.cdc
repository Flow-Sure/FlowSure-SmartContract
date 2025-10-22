import FrothRewards from "./FrothRewards.cdc"
import Scheduler from "./Scheduler.cdc"

access(all) contract AutoCompound {
    
    access(all) event AutoCompoundEnabled(
        user: Address,
        frequency: UFix64,
        timestamp: UFix64
    )
    
    access(all) event AutoCompoundDisabled(
        user: Address,
        timestamp: UFix64
    )
    
    access(all) event RewardsCompounded(
        user: Address,
        rewardAmount: UFix64,
        newTotalStaked: UFix64,
        timestamp: UFix64
    )
    
    access(all) event CompoundScheduled(
        user: Address,
        scheduledFor: UFix64,
        actionId: String,
        timestamp: UFix64
    )
    
    access(all) let AutoCompoundStoragePath: StoragePath
    access(all) let AutoCompoundPublicPath: PublicPath
    
    access(all) var totalCompounds: UInt64
    access(all) var totalRewardsCompounded: UFix64
    
    access(all) struct CompoundConfig {
        access(all) let enabled: Bool
        access(all) let frequency: UFix64
        access(all) let lastCompoundTime: UFix64
        access(all) let nextCompoundTime: UFix64
        access(all) let totalCompounded: UFix64
        access(all) let compoundCount: UInt64
        
        init(
            enabled: Bool,
            frequency: UFix64,
            lastCompoundTime: UFix64,
            nextCompoundTime: UFix64,
            totalCompounded: UFix64,
            compoundCount: UInt64
        ) {
            self.enabled = enabled
            self.frequency = frequency
            self.lastCompoundTime = lastCompoundTime
            self.nextCompoundTime = nextCompoundTime
            self.totalCompounded = totalCompounded
            self.compoundCount = compoundCount
        }
    }
    
    access(all) resource interface AutoCompoundPublic {
        access(all) fun getConfig(): CompoundConfig
        access(all) fun isEnabled(): Bool
        access(all) fun getNextCompoundTime(): UFix64
    }
    
    access(all) resource AutoCompounder: AutoCompoundPublic {
        access(all) var enabled: Bool
        access(all) var frequency: UFix64
        access(all) var lastCompoundTime: UFix64
        access(all) var totalCompounded: UFix64
        access(all) var compoundCount: UInt64
        access(all) var pendingRewards: UFix64
        
        access(all) fun enableAutoCompound(frequency: UFix64) {
            pre {
                frequency >= 3600.0: "Minimum frequency is 1 hour (3600 seconds)"
            }
            
            self.enabled = true
            self.frequency = frequency
            self.lastCompoundTime = getCurrentBlock().timestamp
            
            let nextTime = getCurrentBlock().timestamp + frequency
            self.scheduleNextCompound(nextTime: nextTime)
            
            emit AutoCompoundEnabled(
                user: self.owner?.address ?? panic("No owner"),
                frequency: frequency,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun disableAutoCompound() {
            self.enabled = false
            
            emit AutoCompoundDisabled(
                user: self.owner?.address ?? panic("No owner"),
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun compound(stakerRef: &FrothRewards.FrothStaker) {
            pre {
                self.enabled: "Auto-compound is not enabled"
            }
            
            let userAddress = self.owner?.address ?? panic("No owner")
            let rewardAmount = stakerRef.calculatePendingRewards()
            
            if rewardAmount > 0.0 {
                self.pendingRewards = self.pendingRewards + rewardAmount
                
                let rewardVault <- stakerRef.claimRewards()
                stakerRef.stake(from: <-rewardVault)
                
                self.totalCompounded = self.totalCompounded + rewardAmount
                self.compoundCount = self.compoundCount + 1
                self.lastCompoundTime = getCurrentBlock().timestamp
                self.pendingRewards = 0.0
                
                AutoCompound.totalCompounds = AutoCompound.totalCompounds + 1
                AutoCompound.totalRewardsCompounded = AutoCompound.totalRewardsCompounded + rewardAmount
                
                emit RewardsCompounded(
                    user: userAddress,
                    rewardAmount: rewardAmount,
                    newTotalStaked: stakerRef.getStakedAmount(),
                    timestamp: getCurrentBlock().timestamp
                )
            }
            
            if self.enabled {
                let nextTime = getCurrentBlock().timestamp + self.frequency
                self.scheduleNextCompound(nextTime: nextTime)
            }
        }
        
        access(self) fun scheduleNextCompound(nextTime: UFix64) {
            let actionId = "compound_".concat(self.owner?.address?.toString() ?? "unknown")
                .concat("_").concat(getCurrentBlock().timestamp.toString())
            
            emit CompoundScheduled(
                user: self.owner?.address ?? panic("No owner"),
                scheduledFor: nextTime,
                actionId: actionId,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun calculateRewards(): UFix64 {
            let userAddress = self.owner?.address ?? panic("No owner")
            let stakerData = FrothRewards.getStakerData(user: userAddress)
            
            if stakerData == nil {
                return 0.0
            }
            
            let stakedAmount = stakerData!.stakedAmount
            let timeSinceLastCompound = getCurrentBlock().timestamp - self.lastCompoundTime
            
            let annualRate = 0.12
            let secondsPerYear = 31536000.0
            let rewardRate = annualRate / secondsPerYear
            
            return stakedAmount * rewardRate * timeSinceLastCompound
        }
        
        access(all) fun getConfig(): CompoundConfig {
            let nextTime = self.enabled ? 
                self.lastCompoundTime + self.frequency : 0.0
            
            return CompoundConfig(
                enabled: self.enabled,
                frequency: self.frequency,
                lastCompoundTime: self.lastCompoundTime,
                nextCompoundTime: nextTime,
                totalCompounded: self.totalCompounded,
                compoundCount: self.compoundCount
            )
        }
        
        access(all) fun isEnabled(): Bool {
            return self.enabled
        }
        
        access(all) fun getNextCompoundTime(): UFix64 {
            if !self.enabled {
                return 0.0
            }
            return self.lastCompoundTime + self.frequency
        }
        
        access(all) fun getPendingRewards(): UFix64 {
            return self.calculateRewards()
        }
        
        init() {
            self.enabled = false
            self.frequency = 86400.0
            self.lastCompoundTime = getCurrentBlock().timestamp
            self.totalCompounded = 0.0
            self.compoundCount = 0
            self.pendingRewards = 0.0
        }
    }
    
    access(all) fun createAutoCompounder(): @AutoCompounder {
        return <- create AutoCompounder()
    }
    
    access(all) fun getConfig(user: Address): CompoundConfig? {
        let account = getAccount(user)
        
        if let compounderRef = account.capabilities.borrow<&{AutoCompoundPublic}>(
            self.AutoCompoundPublicPath
        ) {
            return compounderRef.getConfig()
        }
        
        return nil
    }
    
    access(all) fun getTotalCompounds(): UInt64 {
        return self.totalCompounds
    }
    
    access(all) fun getTotalRewardsCompounded(): UFix64 {
        return self.totalRewardsCompounded
    }
    
    init() {
        self.AutoCompoundStoragePath = /storage/FlowSureAutoCompounder
        self.AutoCompoundPublicPath = /public/FlowSureAutoCompounder
        
        self.totalCompounds = 0
        self.totalRewardsCompounded = 0.0
    }
}
