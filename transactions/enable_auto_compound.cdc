import AutoCompound from "../contracts/AutoCompound.cdc"

transaction(frequency: UFix64) {
    prepare(signer: auth(Storage) &Account) {
        let compounderRef = signer.storage.borrow<&AutoCompound.AutoCompounder>(
            from: AutoCompound.AutoCompoundStoragePath
        ) ?? panic("Could not borrow AutoCompounder reference")
        
        compounderRef.enableAutoCompound(frequency: frequency)
    }
}
