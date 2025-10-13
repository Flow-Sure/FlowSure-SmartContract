import DapperAssetProtection from 0x8401ed4fc6788c8a

// Query protected assets for a user
// The ProtectionManager is stored in the user's own account
access(all) fun main(userAddress: Address): [AnyStruct] {
    let account = getAccount(userAddress)
    
    let managerCap = account.capabilities.get<&{DapperAssetProtection.ProtectionManagerPublic}>(
        DapperAssetProtection.ProtectionManagerPublicPath
    )
    
    if let managerRef = managerCap.borrow() {
        let assets = managerRef.getProtectedAssets(user: userAddress)
        let result: [AnyStruct] = []
        
        for asset in assets {
            result.append({
                "assetId": asset.assetId,
                "assetType": asset.assetType,
                "owner": asset.owner,
                "protectedAt": asset.protectedAt,
                "status": asset.status
            })
        }
        
        return result
    }
    
    return []
}
