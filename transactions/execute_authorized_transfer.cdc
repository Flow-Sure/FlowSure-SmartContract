import ScheduledTransfer from 0x8401ed4fc6788c8a

/// Backend service account signs this transaction to execute a scheduled transfer
/// The transfer will come from the user's wallet using their pre-authorized capability
transaction(userAddress: Address, recipient: Address, amount: UFix64) {
  prepare(serviceAccount: auth(Storage) &Account) {
    // Get user's account
    let userAccount = getAccount(userAddress)
    
    // Get the authorization capability
    let authCap = userAccount.capabilities
      .get<&ScheduledTransfer.TransferAuthorization>(/public/scheduledTransferAuth)
      .borrow()
      ?? panic("Could not borrow authorization capability from user account")
    
    // Execute the transfer
    // This will withdraw from user's vault and send to recipient
    authCap.executeTransfer(recipient: recipient, amount: amount)
    
    log("Scheduled transfer executed")
    log("From: ".concat(userAddress.toString()))
    log("To: ".concat(recipient.toString()))
    log("Amount: ".concat(amount.toString()))
  }
}
