import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewardsV2 from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let flowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let rewardsVault: &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue, SaveValue) &Account) {
        // Borrow the signer's FLOW vault
        self.flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
        
        // Check if rewards vault exists, if not create it
        if signer.storage.borrow<&FlowToken.Vault>(from: FrothRewardsV2.RewardsVaultStoragePath) == nil {
            let newRewardsVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            signer.storage.save(<-newRewardsVault, to: FrothRewardsV2.RewardsVaultStoragePath)
            log("Rewards vault created")
        }
        
        // Borrow rewards vault
        self.rewardsVault = signer.storage.borrow<&FlowToken.Vault>(
            from: FrothRewardsV2.RewardsVaultStoragePath
        ) ?? panic("Could not borrow rewards vault")
    }
    
    execute {
        // Withdraw FLOW from signer's vault and deposit to rewards vault
        let tokens <- self.flowVault.withdraw(amount: amount)
        self.rewardsVault.deposit(from: <-tokens)
        log("Funded rewards vault with ".concat(amount.toString()).concat(" FLOW"))
    }
}
