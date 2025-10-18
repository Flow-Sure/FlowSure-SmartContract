import "FlowToken"
import "FungibleToken"
import "IncrementFiConnector"
import "FrothRewards"
import "IFlowSureAction"

/// Execute an insured swap on IncrementFi DEX
/// This transaction creates an insured swap action and executes it
transaction(
    amountIn: UFix64,
    amountOutMin: UFix64,
    slippageTolerance: UFix64,
    retryLimit: UInt8
) {
    let swapAction: IncrementFiConnector.IncrementFiSwapAction
    let insuranceFee: UFix64
    let estimatedOutput: UFix64
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Create insured swap action
        self.swapAction = IncrementFiConnector.createInsuredSwap(
            tokenInType: Type<@FlowToken.Vault>(),
            tokenOutType: Type<@FlowToken.Vault>(),
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            slippageTolerance: slippageTolerance,
            baseFee: 1.0,
            compensationAmount: 5.0,
            retryLimit: retryLimit,
            retryDelay: 30.0
        )
        
        // Calculate insurance fee with FROTH discount
        self.insuranceFee = self.swapAction.estimateFees(user: signer.address)
        
        // Get estimated output
        self.estimatedOutput = self.swapAction.estimateOutput(inputAmount: amountIn)
        
        log("=== IncrementFi Insured Swap ===")
        log("Action ID: ".concat(self.swapAction.uniqueID))
        log("Input: ".concat(amountIn.toString()).concat(" FLOW"))
        log("Estimated Output: ".concat(self.estimatedOutput.toString()).concat(" FLOW"))
        log("Min Output: ".concat(amountOutMin.toString()).concat(" FLOW"))
        log("Slippage Tolerance: ".concat(slippageTolerance.toString()).concat("%"))
        log("Insurance Fee: ".concat(self.insuranceFee.toString()).concat(" FLOW"))
        log("Retry Limit: ".concat(retryLimit.toString()))
    }
    
    execute {
        // Validate swap can be executed
        let params: {String: AnyStruct} = {
            "inputAmount": amountIn,
            "minOutputAmount": amountOutMin
        }
        
        let canExecute = self.swapAction.canExecute(
            user: self.swapAction.timestamp as! Address,
            params: params
        )
        
        if !canExecute {
            panic("Swap cannot be executed: output below minimum")
        }
        
        // Execute the insured swap
        let result = self.swapAction.execute(
            user: self.swapAction.timestamp as! Address,
            params: params
        )
        
        log("=== Swap Result ===")
        log("Success: ".concat(result.success.toString()))
        log("Message: ".concat(result.message))
        log("Action ID: ".concat(result.actionId))
        
        if result.success {
            log("✅ Swap executed successfully!")
            log("Output: ~".concat(self.estimatedOutput.toString()).concat(" FLOW"))
        } else {
            log("❌ Swap failed - retry will be scheduled")
            log("Retry attempt will occur in 30 seconds")
        }
    }
    
    post {
        log("Transaction complete")
    }
}
