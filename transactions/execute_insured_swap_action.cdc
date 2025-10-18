import "FlowSureActions"
import "FlowToken"
import "FrothRewards"
import "IFlowSureAction"

/// Execute an insured swap using Flow Actions standard
transaction(
    inputAmount: UFix64,
    minOutputAmount: UFix64,
    retryLimit: UInt8
) {
    let action: FlowSureActions.InsuredSwapAction
    let fee: UFix64
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Create insured swap action
        self.action = FlowSureActions.createInsuredSwap(
            inputType: Type<@FlowToken.Vault>(),
            outputType: Type<@FlowToken.Vault>(),
            baseFee: 1.0,
            compensationAmount: 5.0,
            retryLimit: retryLimit,
            retryDelay: 30.0
        )
        
        // Calculate fee with FROTH discount
        self.fee = self.action.estimateFees(user: signer.address)
        
        log("Swap action created: ".concat(self.action.uniqueID))
        log("Input type: ".concat(self.action.getInputType().identifier))
        log("Output type: ".concat(self.action.getOutputType().identifier))
        log("Insurance fee: ".concat(self.fee.toString()))
        log("Estimated output: ".concat(self.action.estimateOutput(inputAmount: inputAmount).toString()))
    }
    
    execute {
        // Check if action can be executed
        let params: {String: AnyStruct} = {
            "inputAmount": inputAmount,
            "minOutputAmount": minOutputAmount,
            "shouldFail": false
        }
        
        let canExecute = self.action.canExecute(
            user: self.action.timestamp as! Address,
            params: params
        )
        
        if !canExecute {
            panic("Swap cannot be executed: invalid parameters")
        }
        
        // Execute the insured swap
        let result = self.action.execute(
            user: self.action.timestamp as! Address,
            params: params
        )
        
        log("Swap result: ".concat(result.message))
        log("Success: ".concat(result.success.toString()))
        log("Action ID: ".concat(result.actionId))
        
        if !result.success {
            log("Swap failed - retry will be scheduled")
        } else {
            log("Swap successful!")
        }
    }
}
