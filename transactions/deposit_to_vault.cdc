import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import InsuranceVault from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let vaultRef: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let vaultPublicRef: &InsuranceVault.Vault
    let signerAddress: Address
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.signerAddress = signer.address
        
        self.vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
        
        let vaultAccount = getAccount(0x8401ed4fc6788c8a)
        self.vaultPublicRef = vaultAccount.capabilities.borrow<&InsuranceVault.Vault>(
            InsuranceVault.VaultPublicPath
        ) ?? panic("Could not borrow InsuranceVault reference")
    }
    
    execute {
        let tokens <- self.vaultRef.withdraw(amount: amount)
        self.vaultPublicRef.deposit(from: <-tokens, depositor: self.signerAddress)
        log("Successfully deposited ".concat(amount.toString()).concat(" FLOW to insurance vault"))
    }
}
