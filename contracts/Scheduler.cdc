access(all) contract Scheduler {
    
    access(all) event RetryScheduledEvent(
        user: Address,
        actionId: String,
        attempt: UInt8,
        scheduledFor: UFix64,
        timestamp: UFix64
    )
    
    access(all) event TransactionStatusEvent(
        user: Address,
        actionId: String,
        status: String,
        retries: UInt8,
        timestamp: UFix64
    )
    
    access(all) let SchedulerStoragePath: StoragePath
    
    access(all) struct ScheduledAction {
        access(all) let actionId: String
        access(all) let user: Address
        access(all) let targetAction: String
        access(all) let params: {String: AnyStruct}
        access(all) let retryCount: UInt8
        access(all) let retryLimit: UInt8
        access(all) let scheduledFor: UFix64
        access(all) let createdAt: UFix64
        
        init(
            actionId: String,
            user: Address,
            targetAction: String,
            params: {String: AnyStruct},
            retryCount: UInt8,
            retryLimit: UInt8,
            scheduledFor: UFix64
        ) {
            self.actionId = actionId
            self.user = user
            self.targetAction = targetAction
            self.params = params
            self.retryCount = retryCount
            self.retryLimit = retryLimit
            self.scheduledFor = scheduledFor
            self.createdAt = getCurrentBlock().timestamp
        }
    }
    
    access(all) resource SchedulerManager {
        access(self) var scheduledActions: {String: ScheduledAction}
        access(self) var actionRetryCount: {String: UInt8}
        
        access(all) fun scheduleRetry(
            actionId: String,
            user: Address,
            targetAction: String,
            params: {String: AnyStruct},
            retryLimit: UInt8,
            delay: UFix64
        ) {
            let currentRetries = self.actionRetryCount[actionId] ?? 0
            
            if currentRetries >= retryLimit {
                emit TransactionStatusEvent(
                    user: user,
                    actionId: actionId,
                    status: "RETRY_LIMIT_EXCEEDED",
                    retries: currentRetries,
                    timestamp: getCurrentBlock().timestamp
                )
                return
            }
            
            let newRetryCount = currentRetries + 1
            self.actionRetryCount[actionId] = newRetryCount
            
            let scheduledFor = getCurrentBlock().timestamp + delay
            
            let scheduledAction = ScheduledAction(
                actionId: actionId,
                user: user,
                targetAction: targetAction,
                params: params,
                retryCount: newRetryCount,
                retryLimit: retryLimit,
                scheduledFor: scheduledFor
            )
            
            self.scheduledActions[actionId] = scheduledAction
            
            emit RetryScheduledEvent(
                user: user,
                actionId: actionId,
                attempt: newRetryCount,
                scheduledFor: scheduledFor,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun getScheduledAction(actionId: String): ScheduledAction? {
            return self.scheduledActions[actionId]
        }
        
        access(all) fun removeScheduledAction(actionId: String) {
            self.scheduledActions.remove(key: actionId)
        }
        
        access(all) fun getRetryCount(actionId: String): UInt8 {
            return self.actionRetryCount[actionId] ?? 0
        }
        
        access(all) fun getAllScheduledActions(): [ScheduledAction] {
            let actions: [ScheduledAction] = []
            for action in self.scheduledActions.values {
                actions.append(action)
            }
            return actions
        }
        
        access(all) fun isReadyForRetry(actionId: String): Bool {
            if let action = self.scheduledActions[actionId] {
                return getCurrentBlock().timestamp >= action.scheduledFor
            }
            return false
        }
        
        init() {
            self.scheduledActions = {}
            self.actionRetryCount = {}
        }
    }
    
    access(account) fun borrowSchedulerManager(): &SchedulerManager {
        return self.account.storage.borrow<&SchedulerManager>(
            from: self.SchedulerStoragePath
        ) ?? panic("Could not borrow SchedulerManager reference")
    }
    
    init() {
        self.SchedulerStoragePath = /storage/FlowSureScheduler
        
        let scheduler <- create SchedulerManager()
        self.account.storage.save(<-scheduler, to: self.SchedulerStoragePath)
    }
}
