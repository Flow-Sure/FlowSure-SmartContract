transaction {
    prepare(signer: auth(LoadValue, SaveValue, Capabilities) &Account) {
        // Remove all Froth-related storage
        let paths = [
            /storage/FlowSureFrothStaker,
            /storage/FlowSureFrothStakerV2,
            /storage/FlowSureStakingVault,
            /storage/FlowSureStakingVaultV2
        ]
        
        for path in paths {
            if let res <- signer.storage.load<@AnyResource>(from: path) {
                destroy res
                log("Removed resource at ".concat(path.toString()))
            }
        }
        
        // Unpublish capabilities
        signer.capabilities.unpublish(/public/FlowSureFrothStaker)
        signer.capabilities.unpublish(/public/FlowSureFrothStakerV2)
        
        log("Force cleanup complete")
    }
}
