import FrothRewardsV2 from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(SaveValue, BorrowValue, StorageCapabilities, Capabilities) &Account) {
        // Check if staker already exists
        if signer.storage.borrow<&FrothRewardsV2.FrothStaker>(from: FrothRewardsV2.StakerStoragePath) != nil {
            log("Staker already exists")
            return
        }
        
        // Create new staker
        let staker <- FrothRewardsV2.createStaker()
        signer.storage.save(<-staker, to: FrothRewardsV2.StakerStoragePath)
        
        // Create public capability
        let cap = signer.capabilities.storage.issue<&FrothRewardsV2.FrothStaker>(
            FrothRewardsV2.StakerStoragePath
        )
        signer.capabilities.publish(cap, at: FrothRewardsV2.StakerPublicPath)
        
        log("FrothStaker created successfully")
    }
}
