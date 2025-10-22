import ScheduledTransfer from "../contracts/ScheduledTransfer.cdc"

// Script to check if a user has valid authorization for scheduled transfers
access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let userAccount = getAccount(userAddress)
    
    // Try to get authorization manager
    let authManagerRef = userAccount.getCapability<&ScheduledTransfer.AuthorizationManager{ScheduledTransfer.AuthorizationPublic}>(
        ScheduledTransfer.AuthorizationPublicPath
    ).borrow()
    
    if authManagerRef == nil {
        return {
            "hasAuthorization": false,
            "isValid": false,
            "maxAmount": 0.0,
            "expiryDate": 0.0,
            "message": "No authorization manager found"
        }
    }
    
    let isValid = authManagerRef!.isValid()
    let maxAmount = authManagerRef!.getMaxAmount()
    let expiryDate = authManagerRef!.getExpiryDate()
    let authId = authManagerRef!.getAuthId()
    
    return {
        "hasAuthorization": true,
        "isValid": isValid,
        "authId": authId,
        "maxAmount": maxAmount,
        "expiryDate": expiryDate,
        "message": isValid ? "Authorization is valid" : "Authorization expired or inactive"
    }
}
