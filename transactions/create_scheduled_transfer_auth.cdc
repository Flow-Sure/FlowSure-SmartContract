import ScheduledTransfer from "../contracts/ScheduledTransfer.cdc"

// Transaction for users to authorize scheduled transfers
// This must be signed by the user when they schedule a transfer
transaction(maxAmountPerTransfer: UFix64, expiryDays: UFix64) {
    
    prepare(signer: AuthAccount) {
        // Calculate expiry date (current time + days in seconds)
        let expiryDate = getCurrentBlock().timestamp + (expiryDays * 86400.0)
        
        // Check if authorization manager already exists
        if signer.borrow<&ScheduledTransfer.AuthorizationManager>(
            from: ScheduledTransfer.AuthorizationStoragePath
        ) == nil {
            // Create new authorization manager
            let authManager <- ScheduledTransfer.createAuthorizationManager()
            signer.save(<-authManager, to: ScheduledTransfer.AuthorizationStoragePath)
            
            // Link public capability
            signer.link<&ScheduledTransfer.AuthorizationManager{ScheduledTransfer.AuthorizationPublic}>(
                ScheduledTransfer.AuthorizationPublicPath,
                target: ScheduledTransfer.AuthorizationStoragePath
            )
        }
        
        // Get authorization manager reference
        let authManagerRef = signer.borrow<&ScheduledTransfer.AuthorizationManager>(
            from: ScheduledTransfer.AuthorizationStoragePath
        ) ?? panic("Could not borrow authorization manager")
        
        // Create new authorization
        let authId = authManagerRef.createAuthorization(
            maxAmountPerTransfer: maxAmountPerTransfer,
            expiryDate: expiryDate
        )
        
        log("Authorization created: ".concat(authId))
        log("Max amount per transfer: ".concat(maxAmountPerTransfer.toString()))
        log("Expiry date: ".concat(expiryDate.toString()))
    }
    
    execute {
        log("Scheduled transfer authorization created successfully")
    }
}
