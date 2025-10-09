import InsuredAction from "../contracts/InsuredAction.cdc"

transaction(actionId: String) {
    let actionManagerRef: &InsuredAction.ActionManager
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.actionManagerRef = InsuredAction.borrowActionManager()
    }
    
    execute {
        let result = self.actionManagerRef.executeScheduledRetry(actionId: actionId)
        
        if result.success {
            log("Retry executed successfully: ".concat(result.message))
        } else {
            log("Retry failed: ".concat(result.message))
        }
    }
}
