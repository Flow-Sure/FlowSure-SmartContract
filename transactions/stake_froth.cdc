import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewardsV2 from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let stakerRef: &FrothRewardsV2.FrothStaker
    let flowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewardsV2.FrothStaker>(
            from: FrothRewardsV2.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference. Run create_froth_staker.cdc first")
        
        self.flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
    }
    
    execute {
        let tokens <- self.flowVault.withdraw(amount: amount)
        self.stakerRef.stake(from: <-tokens)
        let discount = self.stakerRef.getDiscount()
        log("Successfully staked ".concat(amount.toString()).concat(" FLOW"))
        log("Current discount: ".concat((discount * 100.0).toString()).concat("%"))
        log("Total staked: ".concat(self.stakerRef.getStakedAmount().toString()))
    }
}
