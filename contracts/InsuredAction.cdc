import Events from "./Events.cdc"
import InsuranceVault from "./InsuranceVault.cdc"
import Scheduler from "./Scheduler.cdc"

access(all) contract InsuredAction {
    
    access(all) let ActionManagerStoragePath: StoragePath
    
    access(all) var defaultRetryDelay: UFix64
    access(all) var defaultCompensationAmount: UFix64
    access(all) var totalActionsExecuted: UInt64
    access(all) var totalActionsSucceeded: UInt64
    access(all) var totalActionsFailed: UInt64
    
    access(all) struct ActionResult {
        access(all) let success: Bool
        access(all) let message: String
        access(all) let data: {String: AnyStruct}?
        
        init(success: Bool, message: String, data: {String: AnyStruct}?) {
            self.success = success
            self.message = message
            self.data = data
        }
    }
    
    access(all) struct ActionRecord {
        access(all) let actionId: String
        access(all) let user: Address
        access(all) let targetAction: String
        access(all) let status: String
        access(all) let retries: UInt8
        access(all) let createdAt: UFix64
        access(all) let lastAttemptAt: UFix64
        
        init(
            actionId: String,
            user: Address,
            targetAction: String,
            status: String,
            retries: UInt8,
            createdAt: UFix64,
            lastAttemptAt: UFix64
        ) {
            self.actionId = actionId
            self.user = user
            self.targetAction = targetAction
            self.status = status
            self.retries = retries
            self.createdAt = createdAt
            self.lastAttemptAt = lastAttemptAt
        }
    }
    
    access(all) resource ActionManager {
        access(self) var actionRecords: {String: ActionRecord}
        access(self) var actionCounter: UInt64
        
        access(all) fun insuredAction(
            user: Address,
            targetAction: String,
            params: {String: AnyStruct},
            retryLimit: UInt8
        ): String {
            self.actionCounter = self.actionCounter + 1
            let actionId = "action_".concat(self.actionCounter.toString())
            
            let record = ActionRecord(
                actionId: actionId,
                user: user,
                targetAction: targetAction,
                status: "INITIATED",
                retries: 0,
                createdAt: getCurrentBlock().timestamp,
                lastAttemptAt: getCurrentBlock().timestamp
            )
            self.actionRecords[actionId] = record
            
            InsuredAction.totalActionsExecuted = InsuredAction.totalActionsExecuted + 1
            
            let result = self.executeAction(
                actionId: actionId,
                user: user,
                targetAction: targetAction,
                params: params,
                retryLimit: retryLimit
            )
            
            return actionId
        }
        
        access(self) fun executeAction(
            actionId: String,
            user: Address,
            targetAction: String,
            params: {String: AnyStruct},
            retryLimit: UInt8
        ): ActionResult {
            let result = self.performAction(targetAction: targetAction, params: params)
            
            if result.success {
                self.handleSuccess(actionId: actionId, user: user, targetAction: targetAction)
                return result
            } else {
                self.handleFailure(
                    actionId: actionId,
                    user: user,
                    targetAction: targetAction,
                    params: params,
                    retryLimit: retryLimit,
                    error: result.message
                )
                return result
            }
        }
        
        access(self) fun performAction(targetAction: String, params: {String: AnyStruct}): ActionResult {
            switch targetAction {
                case "token_swap":
                    return self.simulateTokenSwap(params: params)
                case "nft_mint":
                    return self.simulateNFTMint(params: params)
                case "token_transfer":
                    return self.simulateTokenTransfer(params: params)
                default:
                    return ActionResult(
                        success: false,
                        message: "Unknown action type: ".concat(targetAction),
                        data: nil
                    )
            }
        }
        
        access(self) fun simulateTokenSwap(params: {String: AnyStruct}): ActionResult {
            let shouldFail = params["shouldFail"] as? Bool ?? false
            
            if shouldFail {
                return ActionResult(
                    success: false,
                    message: "Token swap failed: Insufficient liquidity",
                    data: nil
                )
            }
            
            return ActionResult(
                success: true,
                message: "Token swap executed successfully",
                data: {"swapId": "swap_123", "amountOut": "100.0"}
            )
        }
        
        access(self) fun simulateNFTMint(params: {String: AnyStruct}): ActionResult {
            let shouldFail = params["shouldFail"] as? Bool ?? false
            
            if shouldFail {
                return ActionResult(
                    success: false,
                    message: "NFT mint failed: Collection not found",
                    data: nil
                )
            }
            
            return ActionResult(
                success: true,
                message: "NFT minted successfully",
                data: {"nftId": "nft_456"}
            )
        }
        
        access(self) fun simulateTokenTransfer(params: {String: AnyStruct}): ActionResult {
            let shouldFail = params["shouldFail"] as? Bool ?? false
            
            if shouldFail {
                return ActionResult(
                    success: false,
                    message: "Token transfer failed: Insufficient balance",
                    data: nil
                )
            }
            
            return ActionResult(
                success: true,
                message: "Token transfer completed",
                data: {"txId": "tx_789"}
            )
        }
        
        access(self) fun handleSuccess(actionId: String, user: Address, targetAction: String) {
            let record = ActionRecord(
                actionId: actionId,
                user: user,
                targetAction: targetAction,
                status: "SUCCESS",
                retries: self.actionRecords[actionId]?.retries ?? 0,
                createdAt: self.actionRecords[actionId]?.createdAt ?? getCurrentBlock().timestamp,
                lastAttemptAt: getCurrentBlock().timestamp
            )
            self.actionRecords[actionId] = record
            
            InsuredAction.totalActionsSucceeded = InsuredAction.totalActionsSucceeded + 1
            
            emit Events.ActionSuccessEvent(
                user: user,
                actionId: actionId,
                targetAction: targetAction,
                timestamp: getCurrentBlock().timestamp
            )
            
            emit Events.TransactionStatusEvent(
                user: user,
                actionId: actionId,
                status: "SUCCESS",
                retries: record.retries,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(self) fun handleFailure(
            actionId: String,
            user: Address,
            targetAction: String,
            params: {String: AnyStruct},
            retryLimit: UInt8,
            error: String
        ) {
            let currentRetries = self.actionRecords[actionId]?.retries ?? 0
            
            emit Events.ActionFailureEvent(
                user: user,
                actionId: actionId,
                targetAction: targetAction,
                error: error,
                timestamp: getCurrentBlock().timestamp
            )
            
            if currentRetries < retryLimit {
                let schedulerRef = Scheduler.borrowSchedulerManager()
                schedulerRef.scheduleRetry(
                    actionId: actionId,
                    user: user,
                    targetAction: targetAction,
                    params: params,
                    retryLimit: retryLimit,
                    delay: InsuredAction.defaultRetryDelay
                )
                
                let record = ActionRecord(
                    actionId: actionId,
                    user: user,
                    targetAction: targetAction,
                    status: "RETRY_SCHEDULED",
                    retries: currentRetries + 1,
                    createdAt: self.actionRecords[actionId]?.createdAt ?? getCurrentBlock().timestamp,
                    lastAttemptAt: getCurrentBlock().timestamp
                )
                self.actionRecords[actionId] = record
            } else {
                self.triggerCompensation(actionId: actionId, user: user)
            }
        }
        
        access(self) fun triggerCompensation(actionId: String, user: Address) {
            let record = ActionRecord(
                actionId: actionId,
                user: user,
                targetAction: self.actionRecords[actionId]?.targetAction ?? "unknown",
                status: "COMPENSATED",
                retries: self.actionRecords[actionId]?.retries ?? 0,
                createdAt: self.actionRecords[actionId]?.createdAt ?? getCurrentBlock().timestamp,
                lastAttemptAt: getCurrentBlock().timestamp
            )
            self.actionRecords[actionId] = record
            
            InsuredAction.totalActionsFailed = InsuredAction.totalActionsFailed + 1
            
            InsuranceVault.payOut(user: user, amount: InsuredAction.defaultCompensationAmount)
            
            emit Events.CompensationEvent(
                user: user,
                actionId: actionId,
                amount: InsuredAction.defaultCompensationAmount,
                timestamp: getCurrentBlock().timestamp
            )
            
            emit Events.TransactionStatusEvent(
                user: user,
                actionId: actionId,
                status: "FAILED_COMPENSATED",
                retries: record.retries,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun executeScheduledRetry(actionId: String): ActionResult {
            let schedulerRef = Scheduler.borrowSchedulerManager()
            
            guard let scheduledAction = schedulerRef.getScheduledAction(actionId: actionId) else {
                return ActionResult(
                    success: false,
                    message: "Scheduled action not found",
                    data: nil
                )
            }
            
            if !schedulerRef.isReadyForRetry(actionId: actionId) {
                return ActionResult(
                    success: false,
                    message: "Action not ready for retry yet",
                    data: nil
                )
            }
            
            schedulerRef.removeScheduledAction(actionId: actionId)
            
            return self.executeAction(
                actionId: actionId,
                user: scheduledAction.user,
                targetAction: scheduledAction.targetAction,
                params: scheduledAction.params,
                retryLimit: scheduledAction.retryLimit
            )
        }
        
        access(all) fun getActionRecord(actionId: String): ActionRecord? {
            return self.actionRecords[actionId]
        }
        
        access(all) fun getAllActionRecords(): [ActionRecord] {
            let records: [ActionRecord] = []
            for record in self.actionRecords.values {
                records.append(record)
            }
            return records
        }
        
        init() {
            self.actionRecords = {}
            self.actionCounter = 0
        }
    }
    
    access(all) fun borrowActionManager(): &ActionManager {
        return self.account.storage.borrow<&ActionManager>(
            from: self.ActionManagerStoragePath
        ) ?? panic("Could not borrow ActionManager reference")
    }
    
    access(all) fun getStats(): {String: UInt64} {
        return {
            "totalActionsExecuted": self.totalActionsExecuted,
            "totalActionsSucceeded": self.totalActionsSucceeded,
            "totalActionsFailed": self.totalActionsFailed
        }
    }
    
    init() {
        self.ActionManagerStoragePath = /storage/FlowSureActionManager
        
        self.defaultRetryDelay = 60.0
        self.defaultCompensationAmount = 1.0
        self.totalActionsExecuted = 0
        self.totalActionsSucceeded = 0
        self.totalActionsFailed = 0
        
        let actionManager <- create ActionManager()
        self.account.storage.save(<-actionManager, to: self.ActionManagerStoragePath)
    }
}
