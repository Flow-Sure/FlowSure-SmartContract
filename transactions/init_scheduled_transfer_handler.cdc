import ScheduledTransfer from 0x8401ed4fc6788c8a
import FlowTransactionScheduler from 0xf233dcee88fe0abe

// Initialize the scheduled transfer handler for a user
// This must be called once before scheduling any transfers
transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Save a handler resource to storage if not already present
        if signer.storage.borrow<&AnyResource>(from: ScheduledTransfer.HandlerStoragePath) == nil {
            let handler <- ScheduledTransfer.createHandler()
            signer.storage.save(<-handler, to: ScheduledTransfer.HandlerStoragePath)
        }

        // Issue an entitled capability for the handler that can execute transactions
        let _ = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(ScheduledTransfer.HandlerStoragePath)

        // Issue a non-entitled public capability for the handler
        let publicCap = signer.capabilities.storage
            .issue<&{FlowTransactionScheduler.TransactionHandler}>(ScheduledTransfer.HandlerStoragePath)

        // Publish the public capability
        signer.capabilities.publish(publicCap, at: ScheduledTransfer.HandlerPublicPath)
        
        log("Scheduled transfer handler initialized")
    }
}
