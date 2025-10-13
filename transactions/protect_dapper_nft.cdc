import DapperAssetProtection from 0x8401ed4fc6788c8a

// Protect a Dapper NFT (NBA Top Shot, NFL All Day, or Disney Pinnacle)
// assetType: "nba_topshot", "nfl_allday", or "disney_pinnacle"
// actionType: "mint", "pack_opening", or "transfer"
transaction(assetType: String, assetId: UInt64, actionType: String) {
    let managerRef: &DapperAssetProtection.ProtectionManager
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.managerRef = signer.storage.borrow<&DapperAssetProtection.ProtectionManager>(
            from: DapperAssetProtection.ProtectionManagerStoragePath
        ) ?? panic("Could not borrow ProtectionManager reference. Run create_protection_manager.cdc first")
    }
    
    execute {
        let actionId = self.managerRef.insureDapperAsset(
            user: self.managerRef.owner!.address,
            assetType: assetType,
            assetId: assetId,
            actionType: actionType
        )
        
        log("Successfully protected Dapper NFT")
        log("Asset Type: ".concat(assetType))
        log("Asset ID: ".concat(assetId.toString()))
        log("Action ID: ".concat(actionId))
        log("Action Type: ".concat(actionType))
    }
}
