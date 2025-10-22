import ScheduledTransfer from 0x8401ed4fc6788c8a

/// Check if a user has authorized the backend for scheduled transfers
access(all) fun main(userAddress: Address): {String: AnyStruct} {
  let userAccount = getAccount(userAddress)
  
  // Try to borrow the authorization capability
  if let authCap = userAccount.capabilities
    .get<&ScheduledTransfer.TransferAuthorization>(/public/scheduledTransferAuth)
    .borrow() {
    
    return {
      "isAuthorized": true,
      "maxAmountPerTransfer": authCap.maxAmountPerTransfer,
      "authorizedAccount": authCap.authorizedAccount,
      "isRevoked": authCap.isRevoked
    }
  }
  
  return {
    "isAuthorized": false,
    "maxAmountPerTransfer": 0.0,
    "authorizedAccount": nil,
    "isRevoked": false
  }
}
