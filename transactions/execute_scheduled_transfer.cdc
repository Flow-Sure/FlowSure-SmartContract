import ScheduledTransfer from "../contracts/ScheduledTransfer.cdc"
import FungibleToken from "../contracts/interfaces/FungibleToken.cdc"
import FlowToken from "../contracts/connectors/FlowToken.cdc"

// Transaction for backend service to execute scheduled transfers
// This is signed by the service account, NOT the user
transaction(userAddress: Address, recipient: Address, amount: UFix64, retryLimit: UInt8) {
    
    let serviceAccountRef: &ScheduledTransfer.ServiceAccount
    
    prepare(serviceAccount: AuthAccount) {
        // Get service account reference
        self.serviceAccountRef = serviceAccount.borrow<&ScheduledTransfer.ServiceAccount>(
            from: ScheduledTransfer.ServiceAccountStoragePath
        ) ?? panic("Could not borrow service account")
    }
    
    execute {
        // Execute the scheduled transfer
        let transferId = self.serviceAccountRef.executeScheduledTransfer(
            userAddress: userAddress,
            recipient: recipient,
            amount: amount,
            retryLimit: retryLimit
        )
        
        log("Scheduled transfer executed: ".concat(transferId))
        log("User: ".concat(userAddress.toString()))
        log("Recipient: ".concat(recipient.toString()))
        log("Amount: ".concat(amount.toString()))
    }
}
