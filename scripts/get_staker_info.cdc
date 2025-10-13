import FrothRewards from 0x8401ed4fc6788c8a

access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    
    if let stakerCap = account.capabilities.get<&FrothRewards.FrothStaker>(
        FrothRewards.StakerPublicPath
    ) {
        if let stakerRef = stakerCap.borrow() {
            return {
                "address": address,
                "stakedAmount": stakerRef.getStakedAmount(),
                "discount": stakerRef.getDiscount(),
                "discountPercentage": stakerRef.getDiscount() * 100.0
            }
        }
    }
    
    return {
        "address": address,
        "stakedAmount": 0.0,
        "discount": 0.0,
        "discountPercentage": 0.0,
        "error": "No staker found for this address"
    }
}
