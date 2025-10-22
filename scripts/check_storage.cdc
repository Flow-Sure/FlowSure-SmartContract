access(all) fun main(address: Address): {String: String} {
    let account = getAccount(address)
    var result: {String: String} = {}
    
    // Check V2 storage path
    account.storage.forEachStored(fun (path: StoragePath, type: Type): Bool {
        if path.toString().contains("Froth") || path.toString().contains("Staker") {
            result[path.toString()] = type.identifier
        }
        return true
    })
    
    return result
}
