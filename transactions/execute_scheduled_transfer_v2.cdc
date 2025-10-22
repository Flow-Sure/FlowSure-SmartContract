import ScheduledTransfer from "../contracts/ScheduledTransfer.cdc"
import FungibleToken from "../contracts/interfaces/FungibleToken.cdc"
import FlowToken from "../contracts/connectors/FlowToken.cdc"

// Transaction for backend service to execute scheduled transfers
// This uses the user's pre-authorized capability to withdraw and transfer funds
transaction(userAddress: Address, recipient: Address, amount: UFix64) {
    
    let userVaultCap: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>
    let recipientVaultCap: Capability<&{FungibleToken.Receiver}>
    let serviceAccountRef: &ScheduledTransfer.ServiceAccount
    
    prepare(serviceAccount: auth(BorrowValue) &Account) {
        // Get service account reference for validation
        self.serviceAccountRef = serviceAccount.storage.borrow<&ScheduledTransfer.ServiceAccount>(
            from: ScheduledTransfer.ServiceAccountStoragePath
        ) ?? panic("Could not borrow service account")
        
        // Validate the transfer is authorized
        assert(
            self.serviceAccountRef.validateScheduledTransfer(
                userAddress: userAddress,
                amount: amount
            ),
            message: "Transfer not authorized or exceeds limits"
        )
        
        // Get user's vault capability from the private path they published
        let userAccount = getAccount(userAddress)
        let privatePath = PrivatePath(identifier: "scheduledTransferVault_".concat(userAddress.toString()))!
        
        self.userVaultCap = userAccount.capabilities.get<auth(FungibleToken.Withdraw) &FlowToken.Vault>(privatePath)
        
        assert(self.userVaultCap.check(), message: "User vault capability is invalid")
        
        // Get recipient's receiver capability
        let recipientAccount = getAccount(recipient)
        self.recipientVaultCap = recipientAccount.capabilities.get<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        )
        
        assert(self.recipientVaultCap.check(), message: "Recipient receiver capability is invalid")
    }
    
    execute {
        // Borrow user's vault using the authorized capability
        let userVaultRef = self.userVaultCap.borrow()
            ?? panic("Could not borrow user's vault reference")
        
        // Withdraw tokens from user's vault
        let tokens <- userVaultRef.withdraw(amount: amount)
        
        // Deposit to recipient
        let receiverRef = self.recipientVaultCap.borrow()
            ?? panic("Could not borrow recipient's receiver reference")
        
        receiverRef.deposit(from: <-tokens)
        
        // Record the execution
        self.serviceAccountRef.recordExecution(
            userAddress: userAddress,
            recipient: recipient,
            amount: amount
        )
        
        log("Scheduled transfer executed successfully")
        log("User: ".concat(userAddress.toString()))
        log("Recipient: ".concat(recipient.toString()))
        log("Amount: ".concat(amount.toString()))
    }
}
