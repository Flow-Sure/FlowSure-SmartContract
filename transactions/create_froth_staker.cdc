import FrothRewards from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(SaveValue, BorrowValue, StorageCapabilities, Capabilities) &Account) {
        // Check if staker already exists
        if signer.storage.borrow<&FrothRewards.FrothStaker>(from: FrothRewards.StakerStoragePath) != nil {
            log("Staker already exists")
            return
        }
        
        // Create new staker
        let staker <- FrothRewards.createStaker()
        signer.storage.save(<-staker, to: FrothRewards.StakerStoragePath)
        
        // Create public capability
        let cap = signer.capabilities.storage.issue<&FrothRewards.FrothStaker>(
            FrothRewards.StakerStoragePath
        )
        signer.capabilities.publish(cap, at: FrothRewards.StakerPublicPath)
        
        log("FrothStaker created successfully")
    }
}
