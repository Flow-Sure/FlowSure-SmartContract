import DapperAssetProtection from 0x8401ed4fc6788c8a

access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    
    // Try to get the capability
    let managerCap = account.capabilities.get<&{DapperAssetProtection.ProtectionManagerPublic}>(
        DapperAssetProtection.ProtectionManagerPublicPath
    )
    
    let canBorrow = managerCap.check()
    
    if canBorrow {
        if let managerRef = managerCap.borrow() {
            let assets = managerRef.getProtectedAssets(user: address)
            return {
                "hasCapability": true,
                "canBorrow": true,
                "assetsCount": assets.length,
                "assets": assets
            }
        }
    }
    
    return {
        "hasCapability": true,
        "canBorrow": canBorrow,
        "assetsCount": 0,
        "error": "Cannot borrow capability"
    }
}
