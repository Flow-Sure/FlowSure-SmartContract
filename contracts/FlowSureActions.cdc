import "FungibleToken"
import "FlowToken"
import "IFlowSureAction"
import "InsuranceVault"
import "FrothRewards"
import "Scheduler"

/// FlowSureActions implements the Flow Actions standard with insurance protection
/// This contract provides composable, insured DeFi actions
access(all) contract FlowSureActions {
    
    // Events
    access(all) event ActionRegistered(name: String, actionType: String, author: Address)
    access(all) event ActionExecuted(actionId: String, actionType: String, user: Address, success: Bool)
    access(all) event ActionRetried(actionId: String, retryCount: UInt8, scheduledFor: UFix64)
    
    // Storage paths
    access(all) let RegistryStoragePath: StoragePath
    access(all) let RegistryPublicPath: PublicPath
    
    // Action registry
    access(self) let registeredActions: {String: IFlowSureAction.ActionMetadata}
    
    /// Insured Transfer Action
    /// Transfers tokens with automatic retry and compensation
    access(all) struct InsuredTransferAction: IFlowSureAction.InsuredTransfer {
        access(all) let uniqueID: String
        access(all) let timestamp: UFix64
        access(self) let insuranceParams: IFlowSureAction.InsuranceParams
        
        init(
            baseFee: UFix64,
            compensationAmount: UFix64,
            retryLimit: UInt8,
            retryDelay: UFix64
        ) {
            self.uniqueID = "transfer_".concat(getCurrentBlock().timestamp.toString())
            self.timestamp = getCurrentBlock().timestamp
            self.insuranceParams = IFlowSureAction.InsuranceParams(
                baseFee: baseFee,
                compensationAmount: compensationAmount,
                retryLimit: retryLimit,
                retryDelay: retryDelay
            )
        }
        
        access(all) view fun getActionType(): String {
            return "transfer"
        }
        
        access(all) view fun getInsuranceParams(): IFlowSureAction.InsuranceParams {
            return self.insuranceParams
        }
        
        access(all) view fun getTokenType(): Type {
            return Type<@FlowToken.Vault>()
        }
        
        access(all) view fun canExecute(user: Address, params: {String: AnyStruct}): Bool {
            // Check if user has sufficient balance
            let account = getAccount(user)
            if let vaultRef = account.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenReceiver) {
                let amount = params["amount"] as! UFix64? ?? 0.0
                return vaultRef.balance >= amount
            }
            return false
        }
        
        access(all) view fun estimateFees(user: Address): UFix64 {
            // Apply FROTH discount if user is staking
            let discount = FrothRewards.getDiscount(user: user)
            return self.insuranceParams.baseFee * (1.0 - discount)
        }
        
        access(all) fun execute(user: Address, params: {String: AnyStruct}): IFlowSureAction.ActionResult {
            let recipient = params["recipient"] as! Address? ?? panic("Recipient required")
            let amount = params["amount"] as! UFix64? ?? panic("Amount required")
            
            // This would normally execute the actual transfer
            // For now, we return a simulated result
            let success = params["shouldFail"] as! Bool? ?? false
            
            let result = IFlowSureAction.ActionResult(
                success: !success,
                message: success ? "Transfer failed" : "Transfer successful",
                actionId: self.uniqueID,
                retryCount: 0
            )
            
            emit ActionExecuted(
                actionId: self.uniqueID,
                actionType: self.getActionType(),
                user: user,
                success: result.success
            )
            
            return result
        }
        
        access(FungibleToken.Withdraw) fun transferInsured(
            from: Address,
            to: Address,
            amount: UFix64
        ): IFlowSureAction.ActionResult {
            let params: {String: AnyStruct} = {
                "recipient": to,
                "amount": amount,
                "shouldFail": false
            }
            return self.execute(user: from, params: params)
        }
    }
    
    /// Insured Swap Action
    /// Swaps tokens with automatic retry and compensation
    access(all) struct InsuredSwapAction: IFlowSureAction.InsuredSwapper {
        access(all) let uniqueID: String
        access(all) let timestamp: UFix64
        access(self) let insuranceParams: IFlowSureAction.InsuranceParams
        access(self) let inputType: Type
        access(self) let outputType: Type
        
        init(
            inputType: Type,
            outputType: Type,
            baseFee: UFix64,
            compensationAmount: UFix64,
            retryLimit: UInt8,
            retryDelay: UFix64
        ) {
            self.uniqueID = "swap_".concat(getCurrentBlock().timestamp.toString())
            self.timestamp = getCurrentBlock().timestamp
            self.inputType = inputType
            self.outputType = outputType
            self.insuranceParams = IFlowSureAction.InsuranceParams(
                baseFee: baseFee,
                compensationAmount: compensationAmount,
                retryLimit: retryLimit,
                retryDelay: retryDelay
            )
        }
        
        access(all) view fun getActionType(): String {
            return "swap"
        }
        
        access(all) view fun getInsuranceParams(): IFlowSureAction.InsuranceParams {
            return self.insuranceParams
        }
        
        access(all) view fun getInputType(): Type {
            return self.inputType
        }
        
        access(all) view fun getOutputType(): Type {
            return self.outputType
        }
        
        access(all) view fun estimateOutput(inputAmount: UFix64): UFix64 {
            // Simulated exchange rate: 1:1 for demo
            // In production, this would query a real DEX
            return inputAmount * 0.99 // 1% slippage
        }
        
        access(all) view fun canExecute(user: Address, params: {String: AnyStruct}): Bool {
            // Check if user has sufficient input tokens
            let inputAmount = params["inputAmount"] as! UFix64? ?? 0.0
            return inputAmount > 0.0
        }
        
        access(all) view fun estimateFees(user: Address): UFix64 {
            let discount = FrothRewards.getDiscount(user: user)
            return self.insuranceParams.baseFee * (1.0 - discount)
        }
        
        access(all) fun execute(user: Address, params: {String: AnyStruct}): IFlowSureAction.ActionResult {
            let inputAmount = params["inputAmount"] as! UFix64? ?? panic("Input amount required")
            let minOutput = params["minOutputAmount"] as! UFix64? ?? 0.0
            
            let estimatedOutput = self.estimateOutput(inputAmount: inputAmount)
            let success = estimatedOutput >= minOutput
            
            let result = IFlowSureAction.ActionResult(
                success: success,
                message: success ? "Swap successful" : "Insufficient output amount",
                actionId: self.uniqueID,
                retryCount: 0
            )
            
            emit ActionExecuted(
                actionId: self.uniqueID,
                actionType: self.getActionType(),
                user: user,
                success: result.success
            )
            
            return result
        }
        
        access(FungibleToken.Withdraw) fun swapInsured(
            user: Address,
            inputVault: @{FungibleToken.Vault},
            minOutputAmount: UFix64
        ): @{FungibleToken.Vault} {
            let inputAmount = inputVault.balance
            destroy inputVault
            
            // In production, this would execute real swap
            // For now, return empty vault
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
    }
    
    /// Action Registry Resource
    access(all) resource ActionRegistryResource: IFlowSureAction.ActionRegistry {
        access(self) let actions: {String: IFlowSureAction.ActionMetadata}
        
        init() {
            self.actions = {}
        }
        
        access(all) fun registerAction(metadata: IFlowSureAction.ActionMetadata) {
            let key = metadata.actionType.concat("_").concat(metadata.name)
            self.actions[key] = metadata
            
            emit ActionRegistered(
                name: metadata.name,
                actionType: metadata.actionType,
                author: metadata.author
            )
        }
        
        access(all) view fun getAllActions(): [IFlowSureAction.ActionMetadata] {
            return self.actions.values
        }
        
        access(all) view fun getActionsByType(actionType: String): [IFlowSureAction.ActionMetadata] {
            let filtered: [IFlowSureAction.ActionMetadata] = []
            for metadata in self.actions.values {
                if metadata.actionType == actionType {
                    filtered.append(metadata)
                }
            }
            return filtered
        }
        
        access(all) view fun getActionsByTag(tag: String): [IFlowSureAction.ActionMetadata] {
            let filtered: [IFlowSureAction.ActionMetadata] = []
            for metadata in self.actions.values {
                if metadata.tags.contains(tag) {
                    filtered.append(metadata)
                }
            }
            return filtered
        }
    }
    
    /// Create a new action registry
    access(all) fun createRegistry(): @ActionRegistryResource {
        return <- create ActionRegistryResource()
    }
    
    /// Create an insured transfer action
    access(all) fun createInsuredTransfer(
        baseFee: UFix64,
        compensationAmount: UFix64,
        retryLimit: UInt8,
        retryDelay: UFix64
    ): InsuredTransferAction {
        return InsuredTransferAction(
            baseFee: baseFee,
            compensationAmount: compensationAmount,
            retryLimit: retryLimit,
            retryDelay: retryDelay
        )
    }
    
    /// Create an insured swap action
    access(all) fun createInsuredSwap(
        inputType: Type,
        outputType: Type,
        baseFee: UFix64,
        compensationAmount: UFix64,
        retryLimit: UInt8,
        retryDelay: UFix64
    ): InsuredSwapAction {
        return InsuredSwapAction(
            inputType: inputType,
            outputType: outputType,
            baseFee: baseFee,
            compensationAmount: compensationAmount,
            retryLimit: retryLimit,
            retryDelay: retryDelay
        )
    }
    
    /// Get all registered actions
    access(all) fun getRegisteredActions(): {String: IFlowSureAction.ActionMetadata} {
        return self.registeredActions
    }
    
    init() {
        self.RegistryStoragePath = /storage/FlowSureActionRegistry
        self.RegistryPublicPath = /public/FlowSureActionRegistry
        
        self.registeredActions = {}
        
        // Register default actions
        let transferMetadata = IFlowSureAction.ActionMetadata(
            name: "InsuredTransfer",
            description: "Transfer tokens with automatic retry and compensation",
            actionType: "transfer",
            version: "1.0.0",
            author: self.account.address,
            tags: ["transfer", "insurance", "flow"]
        )
        self.registeredActions["transfer_InsuredTransfer"] = transferMetadata
        
        let swapMetadata = IFlowSureAction.ActionMetadata(
            name: "InsuredSwap",
            description: "Swap tokens with automatic retry and compensation",
            actionType: "swap",
            version: "1.0.0",
            author: self.account.address,
            tags: ["swap", "dex", "insurance", "defi"]
        )
        self.registeredActions["swap_InsuredSwap"] = swapMetadata
    }
}
