transaction(code: String) {
    prepare(signer: auth(UpdateContract) &Account) {
        signer.contracts.update(name: "InsuranceVault", code: code.utf8)
    }
}
