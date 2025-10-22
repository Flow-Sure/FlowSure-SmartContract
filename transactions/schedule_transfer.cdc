import ScheduledTransfer from 0x8401ed4fc6788c8a
import FlowTransactionScheduler from 0xf233dcee88fe0abe
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

// Schedule a transfer to execute at a future time
// The user signs this transaction and pays the gas fees upfront
transaction(
    recipient: Address,
    amount: UFix64,
    delaySeconds: UFix64,
    priority: UInt8,
    executionEffort: UInt64
) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Calculate future timestamp
        let future = getCurrentBlock().timestamp + delaySeconds
        
        // Convert priority
        let pr = priority == 0
            ? FlowTransactionScheduler.Priority.High
            : priority == 1
                ? FlowTransactionScheduler.Priority.Medium
                : FlowTransactionScheduler.Priority.Low
        
        // Create transfer data
        let transferData = ScheduledTransfer.TransferData(
            recipient: recipient,
            amount: amount
        )
        
        // Estimate gas fees
        let estimate = FlowTransactionScheduler.estimate(
            data: transferData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort
        )
        
        // Validate estimation
        assert(
            estimate.timestamp != nil || pr == FlowTransactionScheduler.Priority.Low,
            message: estimate.error ?? "estimation failed"
        )
        
        // Withdraw fees from user's vault
        let vaultRef = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        let fees <- vaultRef.withdraw(amount: estimate.flowFee ?? 0.0) as! @FlowToken.Vault
        
        // Get the entitled handler capability
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        // Get the capability from storage controllers
        let controllers = signer.capabilities.storage.getControllers(forPath: ScheduledTransfer.HandlerStoragePath)
        
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }
        
        assert(handlerCap != nil, message: "Could not get handler capability")
        
        // Schedule the transaction
        FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: transferData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort,
            fees: <-fees
        )
        
        log("Transfer scheduled to ".concat(recipient.toString())
            .concat(" for ").concat(amount.toString())
            .concat(" FLOW at ").concat(future.toString()))
    }
}
