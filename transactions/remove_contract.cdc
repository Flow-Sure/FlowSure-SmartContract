transaction(contractName: String) {
    prepare(signer: auth(RemoveContract) &Account) {
        signer.contracts.remove(name: contractName)
        log("Contract removed: ".concat(contractName))
    }
}
