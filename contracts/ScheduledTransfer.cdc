import FungibleToken from "FungibleToken"
import FlowToken from "FlowToken"
import FlowTransactionScheduler from "FlowTransactionScheduler"

access(all) contract ScheduledTransfer {
    
    // Events
    access(all) event ScheduledTransferExecuted(
        user: Address,
        recipient: Address,
        amount: UFix64,
        timestamp: UFix64
    )
    
    // Storage paths
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    
    // Transfer data structure
    access(all) struct TransferData {
        access(all) let recipient: Address
        access(all) let amount: UFix64
        
        init(recipient: Address, amount: UFix64) {
            self.recipient = recipient
            self.amount = amount
        }
    }
    
    // Handler resource that executes scheduled transfers
    // This implements FlowTransactionScheduler.TransactionHandler
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        access(self) let vaultCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>
        access(all) let userAddress: Address
        
        init(vaultCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>, userAddress: Address) {
            self.vaultCapability = vaultCapability
            self.userAddress = userAddress
        }
        
        // This function is called by Flow's scheduler at the scheduled time
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            log("=== EXECUTING SCHEDULED TRANSFER ===")
            log("Transaction ID: ".concat(id.toString()))
            
            // Parse the transfer data from dictionary (workaround for scheduler serialization)
            let dataDict = data as! {String: AnyStruct}? ?? panic("Invalid transfer data")
            let recipient = dataDict["recipient"] as! Address? ?? panic("Missing recipient")
            let amount = dataDict["amount"] as! UFix64? ?? panic("Missing amount")
            
            log("Recipient from data: ".concat(recipient.toString()))
            log("Amount from data: ".concat(amount.toString()))
            
            // Get the user's vault reference using stored capability
            let vaultRef = self.vaultCapability.borrow()
                ?? panic("Could not borrow user's FlowToken vault")
            
            log("Vault balance before: ".concat(vaultRef.balance.toString()))
            
            // Withdraw tokens
            let tokens <- vaultRef.withdraw(amount: amount)
            
            log("Withdrawn amount: ".concat(tokens.balance.toString()))
            
            // Get recipient's receiver capability
            let recipientAccount = getAccount(recipient)
            let recipientVaultRef = recipientAccount.capabilities
                .get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                .borrow()
                ?? panic("Could not borrow recipient's receiver")
            
            // Deposit tokens to recipient
            recipientVaultRef.deposit(from: <-tokens)
            
            // Emit event
            emit ScheduledTransferExecuted(
                user: self.userAddress,
                recipient: recipient,
                amount: amount,
                timestamp: getCurrentBlock().timestamp
            )
            
            log("Scheduled transfer executed (id: ".concat(id.toString())
                .concat(") to: ").concat(recipient.toString())
                .concat(" amount: ").concat(amount.toString()))
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return ScheduledTransfer.HandlerStoragePath
                case Type<PublicPath>():
                    return ScheduledTransfer.HandlerPublicPath
                default:
                    return nil
            }
        }
    }
    
    // Authorization resource for backend execution
    access(all) resource TransferAuthorization {
        access(self) let withdrawCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>
        access(all) let maxAmountPerTransfer: UFix64
        access(all) let authorizedAccount: Address
        access(all) var isRevoked: Bool
        
        init(
            withdrawCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>,
            maxAmountPerTransfer: UFix64,
            authorizedAccount: Address
        ) {
            self.withdrawCapability = withdrawCapability
            self.maxAmountPerTransfer = maxAmountPerTransfer
            self.authorizedAccount = authorizedAccount
            self.isRevoked = false
        }
        
        // Execute a transfer (called by authorized backend)
        access(all) fun executeTransfer(recipient: Address, amount: UFix64) {
            pre {
                !self.isRevoked: "Authorization has been revoked"
                amount <= self.maxAmountPerTransfer: "Amount exceeds maximum allowed"
            }
            
            // Get vault reference
            let vaultRef = self.withdrawCapability.borrow()
                ?? panic("Could not borrow vault capability")
            
            // Withdraw tokens
            let tokens <- vaultRef.withdraw(amount: amount)
            
            // Get recipient's receiver
            let recipientAccount = getAccount(recipient)
            let recipientVaultRef = recipientAccount.capabilities
                .get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                .borrow()
                ?? panic("Could not borrow recipient's receiver")
            
            // Deposit tokens
            recipientVaultRef.deposit(from: <-tokens)
            
            // Emit event
            emit ScheduledTransferExecuted(
                user: self.withdrawCapability.address,
                recipient: recipient,
                amount: amount,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        // Revoke authorization
        access(all) fun revoke() {
            self.isRevoked = true
        }
    }
    
    // Factory function to create a handler
    access(all) fun createHandler(
        vaultCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>,
        userAddress: Address
    ): @Handler {
        return <- create Handler(vaultCapability: vaultCapability, userAddress: userAddress)
    }
    
    // Factory function to create authorization
    access(all) fun createAuthorization(
        withdrawCapability: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault>,
        maxAmountPerTransfer: UFix64,
        authorizedAccount: Address
    ): @TransferAuthorization {
        return <- create TransferAuthorization(
            withdrawCapability: withdrawCapability,
            maxAmountPerTransfer: maxAmountPerTransfer,
            authorizedAccount: authorizedAccount
        )
    }
    
    init() {
        self.HandlerStoragePath = /storage/ScheduledTransferHandler
        self.HandlerPublicPath = /public/ScheduledTransferHandler
    }
}
