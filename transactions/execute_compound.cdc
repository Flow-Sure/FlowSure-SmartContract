import AutoCompound from "../contracts/AutoCompound.cdc"
import FrothRewards from "../contracts/FrothRewards.cdc"

transaction {
    prepare(signer: auth(Storage) &Account) {
        let compounderRef = signer.storage.borrow<&AutoCompound.AutoCompounder>(
            from: AutoCompound.AutoCompoundStoragePath
        ) ?? panic("Could not borrow AutoCompounder reference")
        
        let stakerRef = signer.storage.borrow<&FrothRewards.FrothStaker>(
            from: FrothRewards.StakerStoragePath
        ) ?? panic("Could not borrow FrothStaker reference")
        
        compounderRef.compound(stakerRef: stakerRef)
    }
}
