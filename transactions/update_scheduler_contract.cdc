transaction(code: String) {
    prepare(signer: auth(UpdateContract) &Account) {
        signer.contracts.update(name: "Scheduler", code: code.utf8)
    }
}
