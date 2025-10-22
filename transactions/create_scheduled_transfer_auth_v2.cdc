import ScheduledTransfer from "../contracts/ScheduledTransfer.cdc"
import FungibleToken from "../contracts/interfaces/FungibleToken.cdc"
import FlowToken from "../contracts/connectors/FlowToken.cdc"

// Transaction for users to authorize scheduled transfers
// This creates BOTH the authorization AND a capability for the backend to use
transaction(maxAmountPerTransfer: UFix64, expiryDays: UFix64, serviceAccountAddress: Address) {
    
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        // Calculate expiry date (current time + days in seconds)
        let expiryDate = getCurrentBlock().timestamp + (expiryDays * 86400.0)
        
        // Check if authorization manager already exists
        if signer.storage.borrow<&ScheduledTransfer.AuthorizationManager>(
            from: ScheduledTransfer.AuthorizationStoragePath
        ) == nil {
            // Create new authorization manager
            let authManager <- ScheduledTransfer.createAuthorizationManager()
            signer.storage.save(<-authManager, to: ScheduledTransfer.AuthorizationStoragePath)
        }
        
        // Unpublish old capability if it exists
        signer.capabilities.unpublish(ScheduledTransfer.AuthorizationPublicPath)
        
        // Create and publish new public capability for authorization checking
        let authCap = signer.capabilities.storage.issue<&ScheduledTransfer.AuthorizationManager>(
            ScheduledTransfer.AuthorizationStoragePath
        )
        signer.capabilities.publish(authCap, at: ScheduledTransfer.AuthorizationPublicPath)
        
        // Get authorization manager reference
        let authManagerRef = signer.storage.borrow<&ScheduledTransfer.AuthorizationManager>(
            from: ScheduledTransfer.AuthorizationStoragePath
        ) ?? panic("Could not borrow authorization manager")
        
        // Create new authorization
        let authId = authManagerRef.createAuthorization(
            maxAmountPerTransfer: maxAmountPerTransfer,
            expiryDate: expiryDate
        )
        
        // Create a capability for the FlowToken vault that allows withdrawals
        // This capability will be used by the backend to execute transfers
        let vaultPath = /storage/flowTokenVault
        
        // Issue a new capability for the vault with Withdraw entitlement
        let vaultCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &FlowToken.Vault>(vaultPath)
        
        // Publish this capability at a private path that only the service account can access
        // We use the user's address in the path to make it unique
        let privatePath = PrivatePath(identifier: "scheduledTransferVault_".concat(signer.address.toString()))!
        signer.capabilities.publish(vaultCap, at: privatePath)
        
        log("Authorization created: ".concat(authId))
        log("Max amount per transfer: ".concat(maxAmountPerTransfer.toString()))
        log("Expiry date: ".concat(expiryDate.toString()))
        log("Vault capability published at: ".concat(privatePath.toString()))
    }
    
    execute {
        log("Scheduled transfer authorization created successfully with vault capability")
    }
}
