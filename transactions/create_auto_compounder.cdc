import AutoCompound from "../contracts/AutoCompound.cdc"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        if signer.storage.borrow<&AutoCompound.AutoCompounder>(
            from: AutoCompound.AutoCompoundStoragePath
        ) == nil {
            let compounder <- AutoCompound.createAutoCompounder()
            signer.storage.save(<-compounder, to: AutoCompound.AutoCompoundStoragePath)
            
            let cap = signer.capabilities.storage.issue<&{AutoCompound.AutoCompoundPublic}>(
                AutoCompound.AutoCompoundStoragePath
            )
            signer.capabilities.publish(cap, at: AutoCompound.AutoCompoundPublicPath)
        }
    }
}
