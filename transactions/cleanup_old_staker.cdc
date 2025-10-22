import FrothRewardsV2 from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(LoadValue, SaveValue) &Account) {
        // Try to load and destroy any old staker at the V2 path
        if let oldStaker <- signer.storage.load<@AnyResource>(from: FrothRewardsV2.StakerStoragePath) {
            destroy oldStaker
            log("Removed old staker")
        }
        
        // Unpublish old capability if it exists
        signer.capabilities.unpublish(FrothRewardsV2.StakerPublicPath)
        log("Cleanup complete")
    }
}
