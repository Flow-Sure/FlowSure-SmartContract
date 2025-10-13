import DapperAssetProtection from 0x8401ed4fc6788c8a

access(all) fun main(address: Address): [AnyStruct] {
    let account = getAccount(address)
    
    if let managerCap = account.capabilities.get<&{DapperAssetProtection.ProtectionManagerPublic}>(
        DapperAssetProtection.ProtectionManagerPublicPath
    ) {
        if let managerRef = managerCap.borrow() {
            let assets = managerRef.getProtectedAssets(user: address)
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
    }
    
    return []
}
