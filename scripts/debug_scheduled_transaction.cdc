import FlowTransactionScheduler from 0xf233dcee88fe0abe
import ScheduledTransfer from 0x8401ed4fc6788c8a

// Debug script to check what data is stored in a scheduled transaction
access(all) fun main(scheduledTxId: UInt64): {String: AnyStruct} {
    // Try to get the scheduled transaction details
    // Note: This might not work if the scheduler doesn't expose this data
    
    return {
        "message": "Scheduled transaction ID: ".concat(scheduledTxId.toString()),
        "note": "The Flow scheduler doesn't expose scheduled transaction data directly. Check the transaction logs when it executes."
    }
}
