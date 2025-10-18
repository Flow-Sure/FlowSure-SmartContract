import FrothRewards from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    prepare(signer: &Account) {
        // Create staker if doesn't exist
        if signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) == nil {
            let staker <- FrothRewards.createFrothStaker()
            signer.storage.save(<-staker, to: FrothRewards.StakerStoragePath)
            
            let cap = signer.capabilities.storage.issue<&FrothRewards.FrothStaker>(
                FrothRewards.StakerStoragePath
            )
            signer.capabilities.publish(cap, at: FrothRewards.StakerPublicPath)
        }
        
        // Borrow staker and stake tokens
        let stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow staker reference")
        
        stakerRef.stake(amount: amount)
    }
}
