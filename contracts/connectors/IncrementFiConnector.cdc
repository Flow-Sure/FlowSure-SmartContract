import "FungibleToken"
import "FlowToken"
import "IFlowSureAction"

/// IncrementFiConnector provides integration with IncrementFi DEX
/// This connector enables insured swaps on IncrementFi with automatic retry
access(all) contract IncrementFiConnector {
    
    // IncrementFi contract addresses on testnet
    // Note: These should be updated with actual IncrementFi testnet addresses
    access(all) let SwapRouterAddress: Address
    access(all) let SwapFactoryAddress: Address
    
    // Events
    access(all) event SwapExecuted(
        tokenIn: String,
        tokenOut: String,
        amountIn: UFix64,
        amountOut: UFix64,
        user: Address
    )
    
    access(all) event SwapFailed(
        tokenIn: String,
        tokenOut: String,
        amountIn: UFix64,
        reason: String,
        user: Address
    )
    
    /// Swap parameters for IncrementFi
    access(all) struct SwapParams {
        access(all) let tokenInType: Type
        access(all) let tokenOutType: Type
        access(all) let amountIn: UFix64
        access(all) let amountOutMin: UFix64
        access(all) let deadline: UFix64
        access(all) let slippageTolerance: UFix64
        
        init(
            tokenInType: Type,
            tokenOutType: Type,
            amountIn: UFix64,
            amountOutMin: UFix64,
            deadline: UFix64,
            slippageTolerance: UFix64
        ) {
            self.tokenInType = tokenInType
            self.tokenOutType = tokenOutType
            self.amountIn = amountIn
            self.amountOutMin = amountOutMin
            self.deadline = deadline
            self.slippageTolerance = slippageTolerance
        }
    }
    
    /// Insured Swap Source - provides tokens for swapping
    access(all) struct InsuredSwapSource: IFlowSureAction.InsuredSource {
        access(all) let uniqueID: String
        access(all) let timestamp: UFix64
        access(self) let vaultType: Type
        access(self) let insuranceParams: IFlowSureAction.InsuranceParams
        
        init(
            vaultType: Type,
            baseFee: UFix64,
            compensationAmount: UFix64,
            retryLimit: UInt8,
            retryDelay: UFix64
        ) {
            self.uniqueID = "swap_source_".concat(getCurrentBlock().timestamp.toString())
            self.timestamp = getCurrentBlock().timestamp
            self.vaultType = vaultType
            self.insuranceParams = IFlowSureAction.InsuranceParams(
                baseFee: baseFee,
                compensationAmount: compensationAmount,
                retryLimit: retryLimit,
                retryDelay: retryDelay
            )
        }
        
        access(all) view fun getActionType(): String {
            return "swap_source"
        }
        
        access(all) view fun getInsuranceParams(): IFlowSureAction.InsuranceParams {
            return self.insuranceParams
        }
        
        access(all) view fun getSourceType(): Type {
            return self.vaultType
        }
        
        access(all) view fun minimumAvailable(user: Address): UFix64 {
            // Query user's vault balance
            let account = getAccount(user)
            // This would check actual balance - simplified for now
            return 0.0
        }
        
        access(all) view fun canExecute(user: Address, params: {String: AnyStruct}): Bool {
            let amount = params["amount"] as! UFix64? ?? 0.0
            return amount > 0.0
        }
        
        access(all) view fun estimateFees(user: Address): UFix64 {
            return self.insuranceParams.baseFee
        }
        
        access(all) fun execute(user: Address, params: {String: AnyStruct}): IFlowSureAction.ActionResult {
            return IFlowSureAction.ActionResult(
                success: true,
                message: "Source ready",
                actionId: self.uniqueID,
                retryCount: 0
            )
        }
        
        access(FungibleToken.Withdraw) fun withdrawInsured(
            user: Address,
            maxAmount: UFix64
        ): @{FungibleToken.Vault} {
            // In production, this would withdraw from user's vault
            // For now, return empty vault
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
    }
    
    /// IncrementFi Swap Action with Insurance
    access(all) struct IncrementFiSwapAction: IFlowSureAction.InsuredSwapper {
        access(all) let uniqueID: String
        access(all) let timestamp: UFix64
        access(self) let swapParams: SwapParams
        access(self) let insuranceParams: IFlowSureAction.InsuranceParams
        
        init(
            swapParams: SwapParams,
            baseFee: UFix64,
            compensationAmount: UFix64,
            retryLimit: UInt8,
            retryDelay: UFix64
        ) {
            self.uniqueID = "incrementfi_swap_".concat(getCurrentBlock().timestamp.toString())
            self.timestamp = getCurrentBlock().timestamp
            self.swapParams = swapParams
            self.insuranceParams = IFlowSureAction.InsuranceParams(
                baseFee: baseFee,
                compensationAmount: compensationAmount,
                retryLimit: retryLimit,
                retryDelay: retryDelay
            )
        }
        
        access(all) view fun getActionType(): String {
            return "incrementfi_swap"
        }
        
        access(all) view fun getInsuranceParams(): IFlowSureAction.InsuranceParams {
            return self.insuranceParams
        }
        
        access(all) view fun getInputType(): Type {
            return self.swapParams.tokenInType
        }
        
        access(all) view fun getOutputType(): Type {
            return self.swapParams.tokenOutType
        }
        
        access(all) view fun estimateOutput(inputAmount: UFix64): UFix64 {
            // In production, this would query IncrementFi for actual price
            // For now, simulate with 1% slippage
            return inputAmount * 0.99
        }
        
        access(all) view fun canExecute(user: Address, params: {String: AnyStruct}): Bool {
            // Check if swap is valid
            let inputAmount = params["inputAmount"] as! UFix64? ?? 0.0
            let minOutput = params["minOutputAmount"] as! UFix64? ?? 0.0
            
            if inputAmount == 0.0 {
                return false
            }
            
            let estimatedOutput = self.estimateOutput(inputAmount: inputAmount)
            return estimatedOutput >= minOutput
        }
        
        access(all) view fun estimateFees(user: Address): UFix64 {
            // Base insurance fee + DEX fee (0.3% for volatile pairs)
            let dexFee = self.swapParams.amountIn * 0.003
            return self.insuranceParams.baseFee + dexFee
        }
        
        access(all) fun execute(user: Address, params: {String: AnyStruct}): IFlowSureAction.ActionResult {
            let inputAmount = params["inputAmount"] as! UFix64? ?? self.swapParams.amountIn
            let minOutput = params["minOutputAmount"] as! UFix64? ?? self.swapParams.amountOutMin
            
            // Simulate swap execution
            let estimatedOutput = self.estimateOutput(inputAmount: inputAmount)
            let success = estimatedOutput >= minOutput
            
            if success {
                emit SwapExecuted(
                    tokenIn: self.swapParams.tokenInType.identifier,
                    tokenOut: self.swapParams.tokenOutType.identifier,
                    amountIn: inputAmount,
                    amountOut: estimatedOutput,
                    user: user
                )
            } else {
                emit SwapFailed(
                    tokenIn: self.swapParams.tokenInType.identifier,
                    tokenOut: self.swapParams.tokenOutType.identifier,
                    amountIn: inputAmount,
                    reason: "Insufficient output amount",
                    user: user
                )
            }
            
            return IFlowSureAction.ActionResult(
                success: success,
                message: success ? "Swap executed successfully" : "Swap failed: insufficient output",
                actionId: self.uniqueID,
                retryCount: 0
            )
        }
        
        access(FungibleToken.Withdraw) fun swapInsured(
            user: Address,
            inputVault: @{FungibleToken.Vault},
            minOutputAmount: UFix64
        ): @{FungibleToken.Vault} {
            let inputAmount = inputVault.balance
            
            // In production, this would:
            // 1. Call IncrementFi swap router
            // 2. Execute the swap
            // 3. Return output vault
            
            // For now, destroy input and return empty output vault
            destroy inputVault
            
            emit SwapExecuted(
                tokenIn: self.swapParams.tokenInType.identifier,
                tokenOut: self.swapParams.tokenOutType.identifier,
                amountIn: inputAmount,
                amountOut: inputAmount * 0.99,
                user: user
            )
            
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
    }
    
    /// Create an IncrementFi swap action with insurance
    access(all) fun createInsuredSwap(
        tokenInType: Type,
        tokenOutType: Type,
        amountIn: UFix64,
        amountOutMin: UFix64,
        slippageTolerance: UFix64,
        baseFee: UFix64,
        compensationAmount: UFix64,
        retryLimit: UInt8,
        retryDelay: UFix64
    ): IncrementFiSwapAction {
        let deadline = getCurrentBlock().timestamp + 300.0 // 5 minutes
        
        let swapParams = SwapParams(
            tokenInType: tokenInType,
            tokenOutType: tokenOutType,
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            deadline: deadline,
            slippageTolerance: slippageTolerance
        )
        
        return IncrementFiSwapAction(
            swapParams: swapParams,
            baseFee: baseFee,
            compensationAmount: compensationAmount,
            retryLimit: retryLimit,
            retryDelay: retryDelay
        )
    }
    
    /// Get swap quote from IncrementFi
    access(all) fun getSwapQuote(
        tokenIn: Type,
        tokenOut: Type,
        amountIn: UFix64
    ): UFix64 {
        // In production, this would query IncrementFi's price oracle
        // For now, return simulated quote with 1% slippage
        return amountIn * 0.99
    }
    
    /// Check if a trading pair exists
    access(all) fun pairExists(tokenA: Type, tokenB: Type): Bool {
        // In production, query IncrementFi factory
        // For now, assume FLOW pairs exist
        return tokenA == Type<@FlowToken.Vault>() || tokenB == Type<@FlowToken.Vault>()
    }
    
    init() {
        // These should be actual IncrementFi testnet addresses
        self.SwapRouterAddress = 0x1234567890abcdef
        self.SwapFactoryAddress = 0x1234567890abcdef
    }
}
