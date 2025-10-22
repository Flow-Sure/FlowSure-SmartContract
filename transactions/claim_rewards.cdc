import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import FrothRewardsV2 from 0x8401ed4fc6788c8a

transaction {
    let stakerRef: &FrothRewardsV2.FrothStaker
    let flowVault: &FlowToken.Vault
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewardsV2.FrothStaker>(
            from: FrothRewardsV2.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
        
        self.flowVault = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault reference")
    }
    
    execute {
        let pendingRewards = self.stakerRef.calculatePendingRewards()
        
        if pendingRewards > 0.0 {
            let rewardTokens <- self.stakerRef.claimRewards()
            self.flowVault.deposit(from: <-rewardTokens)
            log("Successfully claimed ".concat(pendingRewards.toString()).concat(" FLOW in rewards"))
        } else {
            log("No rewards available to claim")
        }
    }
}
