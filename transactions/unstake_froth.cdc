import FrothRewards from 0x8401ed4fc6788c8a

transaction(amount: UFix64) {
    let stakerRef: &FrothRewards.FrothStaker
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
    }
    
    execute {
        self.stakerRef.unstake(amount: amount)
        log("Successfully unstaked ".concat(amount.toString()).concat(" FROTH"))
        log("Remaining staked: ".concat(self.stakerRef.getStakedAmount().toString()))
    }
}
