import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import InsuranceVault from "../contracts/InsuranceVault.cdc"

transaction(amount: UFix64) {
    let vaultRef: &FlowToken.Vault
    let vaultPublicRef: &InsuranceVault.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.vaultRef = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
        
        let vaultAccount = getAccount(InsuranceVault.account.address)
        self.vaultPublicRef = vaultAccount.capabilities.borrow<&InsuranceVault.Vault>(
            InsuranceVault.VaultPublicPath
        ) ?? panic("Could not borrow InsuranceVault reference")
    }
    
    execute {
        let tokens <- self.vaultRef.withdraw(amount: amount)
        self.vaultPublicRef.deposit(from: <-tokens)
    }
}
