import "FlowSureActions"
import "FrothRewards"
import "IFlowSureAction"

/// Execute an insured transfer using Flow Actions standard
transaction(
    recipient: Address,
    amount: UFix64,
    retryLimit: UInt8
) {
    let action: FlowSureActions.InsuredTransferAction
    let fee: UFix64
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Create insured transfer action
        self.action = FlowSureActions.createInsuredTransfer(
            baseFee: 1.0,
            compensationAmount: 5.0,
            retryLimit: retryLimit,
            retryDelay: 30.0
        )
        
        // Calculate fee with FROTH discount
        self.fee = self.action.estimateFees(user: signer.address)
        
        log("Action created: ".concat(self.action.uniqueID))
        log("Action type: ".concat(self.action.getActionType()))
        log("Insurance fee: ".concat(self.fee.toString()))
        log("Retry limit: ".concat(retryLimit.toString()))
    }
    
    execute {
        // Check if action can be executed
        let params: {String: AnyStruct} = {
            "recipient": recipient,
            "amount": amount,
            "shouldFail": false
        }
        
        let canExecute = self.action.canExecute(
            user: self.action.timestamp as! Address,
            params: params
        )
        
        if !canExecute {
            panic("Action cannot be executed: insufficient balance")
        }
        
        // Execute the insured transfer
        let result = self.action.execute(
            user: self.action.timestamp as! Address,
            params: params
        )
        
        log("Execution result: ".concat(result.message))
        log("Success: ".concat(result.success.toString()))
        log("Action ID: ".concat(result.actionId))
        
        if !result.success {
            log("Action failed - retry will be scheduled")
        }
    }
}
