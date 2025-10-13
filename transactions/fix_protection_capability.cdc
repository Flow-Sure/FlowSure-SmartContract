import DapperAssetProtection from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(StorageCapabilities, Capabilities, UnpublishCapability) &Account) {
        // Unpublish old capability if it exists
        signer.capabilities.unpublish(DapperAssetProtection.ProtectionManagerPublicPath)
        
        // Create and publish new capability
        let cap = signer.capabilities.storage.issue<&{DapperAssetProtection.ProtectionManagerPublic}>(
            DapperAssetProtection.ProtectionManagerStoragePath
        )
        signer.capabilities.publish(cap, at: DapperAssetProtection.ProtectionManagerPublicPath)
        
        log("Protection capability fixed and republished")
    }
}
