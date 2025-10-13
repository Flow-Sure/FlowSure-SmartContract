import InsuranceVault from "./InsuranceVault.cdc"
import Scheduler from "./Scheduler.cdc"

access(all) contract DapperAssetProtection {
    
    access(all) event DapperAssetProtectedEvent(
        user: Address,
        assetType: String,
        assetId: UInt64,
        actionId: String,
        timestamp: UFix64
    )
    
    access(all) event DapperAssetCompensatedEvent(
        user: Address,
        assetType: String,
        assetId: UInt64,
        compensation: UFix64,
        timestamp: UFix64
    )
    
    access(all) event DapperActionSuccessEvent(
        user: Address,
        assetType: String,
        assetId: UInt64,
        actionType: String,
        timestamp: UFix64
    )
    
    access(all) event DapperActionRetryEvent(
        user: Address,
        assetType: String,
        assetId: UInt64,
        retryCount: UInt8,
        timestamp: UFix64
    )
    
    access(all) let ProtectionManagerStoragePath: StoragePath
    access(all) let ProtectionManagerPublicPath: PublicPath
    
    access(all) var defaultCompensationAmount: UFix64
    access(all) var totalProtectedAssets: UInt64
    access(all) var totalCompensations: UInt64
    
    access(all) struct ProtectedAsset {
        access(all) let assetId: UInt64
        access(all) let assetType: String
        access(all) let owner: Address
        access(all) let protectedAt: UFix64
        access(all) let status: String
        
        init(assetId: UInt64, assetType: String, owner: Address, protectedAt: UFix64, status: String) {
            self.assetId = assetId
            self.assetType = assetType
            self.owner = owner
            self.protectedAt = protectedAt
            self.status = status
        }
    }
    
    access(all) resource interface ProtectionManagerPublic {
        access(all) fun getProtectedAssets(user: Address): [ProtectedAsset]
        access(all) fun isAssetProtected(user: Address, assetId: UInt64): Bool
    }
    
    access(all) resource ProtectionManager: ProtectionManagerPublic {
        access(self) var protectedAssets: {Address: {UInt64: ProtectedAsset}}
        access(self) var actionCounter: UInt64
        
        access(all) fun insureDapperAsset(
            user: Address,
            assetType: String,
            assetId: UInt64,
            actionType: String
        ): String {
            assert(self.isValidAssetType(assetType), message: "Invalid asset type")
            
            self.actionCounter = self.actionCounter + 1
            let actionId = "dapper_".concat(self.actionCounter.toString())
            
            let asset = ProtectedAsset(
                assetId: assetId,
                assetType: assetType,
                owner: user,
                protectedAt: getCurrentBlock().timestamp,
                status: "PROTECTED"
            )
            
            if self.protectedAssets[user] == nil {
                self.protectedAssets[user] = {}
            }
            self.protectedAssets[user]!.insert(key: assetId, asset)
            
            DapperAssetProtection.totalProtectedAssets = DapperAssetProtection.totalProtectedAssets + 1
            
            emit DapperAssetProtectedEvent(
                user: user,
                assetType: assetType,
                assetId: assetId,
                actionId: actionId,
                timestamp: getCurrentBlock().timestamp
            )
            
            let success = self.performDapperAction(
                user: user,
                assetType: assetType,
                assetId: assetId,
                actionType: actionType
            )
            
            if !success {
                self.scheduleRetry(
                    user: user,
                    assetType: assetType,
                    assetId: assetId,
                    actionType: actionType,
                    retryCount: 1
                )
            } else {
                self.updateAssetStatus(user: user, assetId: assetId, status: "SUCCESS")
            }
            
            return actionId
        }
        
        access(self) fun performDapperAction(
            user: Address,
            assetType: String,
            assetId: UInt64,
            actionType: String
        ): Bool {
            switch assetType {
                case "NBA_TOP_SHOT":
                    return self.handleTopShotAction(assetId: assetId, actionType: actionType)
                case "NFL_ALL_DAY":
                    return self.handleAllDayAction(assetId: assetId, actionType: actionType)
                case "DISNEY_PINNACLE":
                    return self.handleDisneyPinnacleAction(assetId: assetId, actionType: actionType)
                default:
                    return false
            }
        }
        
        access(self) fun handleTopShotAction(assetId: UInt64, actionType: String): Bool {
            switch actionType {
                case "MINT":
                    return self.simulateMint(assetId: assetId)
                case "PACK_OPENING":
                    return self.simulatePackOpening(assetId: assetId)
                case "TRANSFER":
                    return self.simulateTransfer(assetId: assetId)
                default:
                    return false
            }
        }
        
        access(self) fun handleAllDayAction(assetId: UInt64, actionType: String): Bool {
            switch actionType {
                case "MINT":
                    return self.simulateMint(assetId: assetId)
                case "PACK_OPENING":
                    return self.simulatePackOpening(assetId: assetId)
                case "TRANSFER":
                    return self.simulateTransfer(assetId: assetId)
                default:
                    return false
            }
        }
        
        access(self) fun handleDisneyPinnacleAction(assetId: UInt64, actionType: String): Bool {
            switch actionType {
                case "MINT":
                    return self.simulateMint(assetId: assetId)
                case "PIN_OPENING":
                    return self.simulatePackOpening(assetId: assetId)
                case "TRANSFER":
                    return self.simulateTransfer(assetId: assetId)
                default:
                    return false
            }
        }
        
        access(self) fun simulateMint(assetId: UInt64): Bool {
            let random = revertibleRandom<UInt64>() % 100
            return random > 20
        }
        
        access(self) fun simulatePackOpening(assetId: UInt64): Bool {
            let random = revertibleRandom<UInt64>() % 100
            return random > 15
        }
        
        access(self) fun simulateTransfer(assetId: UInt64): Bool {
            let random = revertibleRandom<UInt64>() % 100
            return random > 10
        }
        
        access(self) fun scheduleRetry(
            user: Address,
            assetType: String,
            assetId: UInt64,
            actionType: String,
            retryCount: UInt8
        ) {
            if retryCount <= 3 {
                emit DapperActionRetryEvent(
                    user: user,
                    assetType: assetType,
                    assetId: assetId,
                    retryCount: retryCount,
                    timestamp: getCurrentBlock().timestamp
                )
                
                self.updateAssetStatus(user: user, assetId: assetId, status: "RETRY_SCHEDULED")
            } else {
                self.compensateUser(user: user, assetType: assetType, assetId: assetId)
            }
        }
        
        access(self) fun compensateUser(user: Address, assetType: String, assetId: UInt64) {
            let compensationAmount = DapperAssetProtection.defaultCompensationAmount
            
            InsuranceVault.payOut(user: user, amount: compensationAmount)
            
            self.updateAssetStatus(user: user, assetId: assetId, status: "COMPENSATED")
            
            DapperAssetProtection.totalCompensations = DapperAssetProtection.totalCompensations + 1
            
            emit DapperAssetCompensatedEvent(
                user: user,
                assetType: assetType,
                assetId: assetId,
                compensation: compensationAmount,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(self) fun updateAssetStatus(user: Address, assetId: UInt64, status: String) {
            if let userAssets = self.protectedAssets[user] {
                if let asset = userAssets[assetId] {
                    let updatedAsset = ProtectedAsset(
                        assetId: asset.assetId,
                        assetType: asset.assetType,
                        owner: asset.owner,
                        protectedAt: asset.protectedAt,
                        status: status
                    )
                    self.protectedAssets[user]!.insert(key: assetId, updatedAsset)
                }
            }
        }
        
        access(self) fun isValidAssetType(_ assetType: String): Bool {
            return assetType == "NBA_TOP_SHOT" || 
                   assetType == "NFL_ALL_DAY" || 
                   assetType == "DISNEY_PINNACLE"
        }
        
        access(all) fun getProtectedAssets(user: Address): [ProtectedAsset] {
            let assets: [ProtectedAsset] = []
            
            if let userAssets = self.protectedAssets[user] {
                for asset in userAssets.values {
                    assets.append(asset)
                }
            }
            
            return assets
        }
        
        access(all) fun isAssetProtected(user: Address, assetId: UInt64): Bool {
            if let userAssets = self.protectedAssets[user] {
                return userAssets.containsKey(assetId)
            }
            return false
        }
        
        access(all) fun removeProtection(user: Address, assetId: UInt64) {
            if let userAssets = self.protectedAssets[user] {
                self.protectedAssets[user]!.remove(key: assetId)
            }
        }
        
        init() {
            self.protectedAssets = {}
            self.actionCounter = 0
        }
    }
    
    access(all) fun createProtectionManager(): @ProtectionManager {
        return <- create ProtectionManager()
    }
    
    access(all) fun borrowProtectionManager(): &ProtectionManager {
        return self.account.storage.borrow<&ProtectionManager>(
            from: self.ProtectionManagerStoragePath
        ) ?? panic("Could not borrow ProtectionManager reference")
    }
    
    access(all) fun getStats(): {String: UInt64} {
        return {
            "totalProtectedAssets": self.totalProtectedAssets,
            "totalCompensations": self.totalCompensations
        }
    }
    
    init() {
        self.ProtectionManagerStoragePath = /storage/FlowSureDapperProtection
        self.ProtectionManagerPublicPath = /public/FlowSureDapperProtection
        
        self.defaultCompensationAmount = 5.0
        self.totalProtectedAssets = 0
        self.totalCompensations = 0
        
        let protectionManager <- create ProtectionManager()
        self.account.storage.save(<-protectionManager, to: self.ProtectionManagerStoragePath)
    }
}
