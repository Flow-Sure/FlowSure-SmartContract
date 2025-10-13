import FrothRewards from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let stakerRef: &FrothRewards.FrothStaker
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference. Run create_froth_staker.cdc first")
    }
    
    execute {
        self.stakerRef.stake(amount: amount)
        let discount = self.stakerRef.getDiscount()
        log("Successfully staked ".concat(amount.toString()).concat(" FROTH"))
        log("Current discount: ".concat((discount * 100.0).toString()).concat("%"))
        log("Total staked: ".concat(self.stakerRef.getStakedAmount().toString()))
    }
}
