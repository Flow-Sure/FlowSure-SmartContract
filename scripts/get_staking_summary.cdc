import FrothRewardsV2 from "../contracts/FrothRewardsV2.cdc"

access(all) struct StakingSummary {
    access(all) let userAddress: Address
    access(all) let stakedAmount: UFix64
    access(all) let discount: UFix64
    access(all) let pendingRewards: UFix64
    access(all) let totalStakedGlobal: UFix64
    access(all) let totalStakersGlobal: UInt64
    access(all) let annualRewardRate: UFix64
    
    init(
        userAddress: Address,
        stakedAmount: UFix64,
        discount: UFix64,
        pendingRewards: UFix64,
        totalStakedGlobal: UFix64,
        totalStakersGlobal: UInt64,
        annualRewardRate: UFix64
    ) {
        self.userAddress = userAddress
        self.stakedAmount = stakedAmount
        self.discount = discount
        self.pendingRewards = pendingRewards
        self.totalStakedGlobal = totalStakedGlobal
        self.totalStakersGlobal = totalStakersGlobal
        self.annualRewardRate = annualRewardRate
    }
}

access(all) fun main(user: Address): StakingSummary? {
    let account = getAccount(user)
    
    if let stakerRef = account.capabilities.borrow<&{FrothRewardsV2.StakerPublic}>(
        FrothRewardsV2.StakerPublicPath
    ) {
        return StakingSummary(
            userAddress: user,
            stakedAmount: stakerRef.getStakedAmount(),
            discount: stakerRef.getDiscount(),
            pendingRewards: stakerRef.calculatePendingRewards(),
            totalStakedGlobal: FrothRewardsV2.getTotalStaked(),
            totalStakersGlobal: FrothRewardsV2.getTotalStakers(),
            annualRewardRate: FrothRewardsV2.annualRewardRate
        )
    }
    
    return nil
}
