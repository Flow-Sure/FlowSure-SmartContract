import ScheduledTransfer from 0x8401ed4fc6788c8a
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

/// User signs this transaction to authorize the backend service account
/// to execute scheduled transfers on their behalf
transaction(serviceAccount: Address, maxAmountPerTransfer: UFix64) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Create a withdraw capability from user's vault
    let withdrawCap = signer.capabilities.storage
      .issue<auth(FungibleToken.Withdraw) &FlowToken.Vault>(/storage/flowTokenVault)
    
    // Create the authorization resource
    let auth <- ScheduledTransfer.createAuthorization(
      withdrawCapability: withdrawCap,
      maxAmountPerTransfer: maxAmountPerTransfer,
      authorizedAccount: serviceAccount
    )
    
    // Save it to storage
    signer.storage.save(<-auth, to: /storage/scheduledTransferAuth)
    
    // Publish a public capability so backend can access it
    let authCap = signer.capabilities.storage
      .issue<&ScheduledTransfer.TransferAuthorization>(/storage/scheduledTransferAuth)
    signer.capabilities.publish(authCap, at: /public/scheduledTransferAuth)
    
    log("Backend authorized for scheduled transfers")
    log("Service account: ".concat(serviceAccount.toString()))
    log("Max amount per transfer: ".concat(maxAmountPerTransfer.toString()))
  }
}
