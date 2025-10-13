import DapperAssetProtection from 0x8401ed4fc6788c8a

transaction {
    prepare(signer: auth(SaveValue, BorrowValue, StorageCapabilities, Capabilities) &Account) {
        // Check if protection manager already exists
        if signer.storage.borrow<&DapperAssetProtection.ProtectionManager>(
            from: DapperAssetProtection.ProtectionManagerStoragePath
        ) != nil {
            log("ProtectionManager already exists")
            return
        }
        
        // Create new protection manager
        let manager <- DapperAssetProtection.createProtectionManager()
        signer.storage.save(<-manager, to: DapperAssetProtection.ProtectionManagerStoragePath)
        
        // Create public capability
        let cap = signer.capabilities.storage.issue<&{DapperAssetProtection.ProtectionManagerPublic}>(
            DapperAssetProtection.ProtectionManagerStoragePath
        )
        signer.capabilities.publish(cap, at: DapperAssetProtection.ProtectionManagerPublicPath)
        
        log("ProtectionManager created successfully")
    }
}
