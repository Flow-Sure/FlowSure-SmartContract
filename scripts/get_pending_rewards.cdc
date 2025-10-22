import FrothRewardsV2 from "../contracts/FrothRewardsV2.cdc"

access(all) fun main(user: Address): UFix64 {
    let account = getAccount(user)
    
    if let stakerRef = account.capabilities.borrow<&{FrothRewardsV2.StakerPublic}>(
        FrothRewardsV2.StakerPublicPath
    ) {
        return stakerRef.calculatePendingRewards()
    }
    
    return 0.0
}
