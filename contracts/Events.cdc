access(all) contract Events {
    
    access(all) event TransactionStatusEvent(
        user: Address,
        actionId: String,
        status: String,
        retries: UInt8,
        timestamp: UFix64
    )
    
    access(all) event CompensationEvent(
        user: Address,
        actionId: String,
        amount: UFix64,
        timestamp: UFix64
    )
    
    access(all) event RetryScheduledEvent(
        user: Address,
        actionId: String,
        attempt: UInt8,
        scheduledFor: UFix64,
        timestamp: UFix64
    )
    
    access(all) event ActionSuccessEvent(
        user: Address,
        actionId: String,
        targetAction: String,
        timestamp: UFix64
    )
    
    access(all) event ActionFailureEvent(
        user: Address,
        actionId: String,
        targetAction: String,
        error: String,
        timestamp: UFix64
    )
    
    access(all) event VaultDepositEvent(
        depositor: Address,
        amount: UFix64,
        newBalance: UFix64,
        timestamp: UFix64
    )
    
    access(all) event VaultPayoutEvent(
        recipient: Address,
        amount: UFix64,
        remainingBalance: UFix64,
        timestamp: UFix64
    )
}
