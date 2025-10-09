import InsuredAction from "../contracts/InsuredAction.cdc"

transaction(
    targetAction: String,
    shouldFail: Bool,
    retryLimit: UInt8
) {
    let actionManagerRef: &InsuredAction.ActionManager
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.actionManagerRef = InsuredAction.borrowActionManager()
    }
    
    execute {
        let params: {String: AnyStruct} = {
            "shouldFail": shouldFail
        }
        
        let actionId = self.actionManagerRef.insuredAction(
            user: self.actionManagerRef.owner!.address,
            targetAction: targetAction,
            params: params,
            retryLimit: retryLimit
        )
        
        log("Action executed with ID: ".concat(actionId))
    }
}
