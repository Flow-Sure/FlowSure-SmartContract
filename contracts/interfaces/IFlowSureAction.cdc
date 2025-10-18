import "FungibleToken"

/// IFlowSureAction defines the interface for insured actions in FlowSure
/// This follows the Flow Actions standard (FLIP-339) with insurance capabilities
access(all) contract interface IFlowSureAction {
    
    /// Unique identifier for action traceability
    access(all) struct interface IdentifiableAction {
        access(all) let uniqueID: String
        access(all) let timestamp: UFix64
    }
    
    /// Result of an action execution
    access(all) struct ActionResult {
        access(all) let success: Bool
        access(all) let message: String
        access(all) let actionId: String
        access(all) let retryCount: UInt8
        access(all) let timestamp: UFix64
        
        init(success: Bool, message: String, actionId: String, retryCount: UInt8) {
            self.success = success
            self.message = message
            self.actionId = actionId
            self.retryCount = retryCount
            self.timestamp = getCurrentBlock().timestamp
        }
    }
    
    /// Insurance parameters for an action
    access(all) struct InsuranceParams {
        access(all) let baseFee: UFix64
        access(all) let compensationAmount: UFix64
        access(all) let retryLimit: UInt8
        access(all) let retryDelay: UFix64
        
        init(baseFee: UFix64, compensationAmount: UFix64, retryLimit: UInt8, retryDelay: UFix64) {
            self.baseFee = baseFee
            self.compensationAmount = compensationAmount
            self.retryLimit = retryLimit
            self.retryDelay = retryDelay
        }
    }
    
    /// Base interface for all insured actions
    access(all) struct interface InsuredAction: IdentifiableAction {
        /// Get the action type (e.g., "swap", "transfer", "stake")
        access(all) view fun getActionType(): String
        
        /// Get insurance parameters
        access(all) view fun getInsuranceParams(): InsuranceParams
        
        /// Execute the action with insurance protection
        access(all) fun execute(user: Address, params: {String: AnyStruct}): ActionResult
        
        /// Check if action can be executed
        access(all) view fun canExecute(user: Address, params: {String: AnyStruct}): Bool
        
        /// Get estimated gas/fees
        access(all) view fun estimateFees(user: Address): UFix64
    }
    
    /// Source action - provides tokens with insurance
    access(all) struct interface InsuredSource: InsuredAction {
        /// Get the vault type this source provides
        access(all) view fun getSourceType(): Type
        
        /// Get minimum available amount
        access(all) view fun minimumAvailable(user: Address): UFix64
        
        /// Withdraw tokens with insurance protection
        access(FungibleToken.Withdraw) fun withdrawInsured(
            user: Address,
            maxAmount: UFix64
        ): @{FungibleToken.Vault}
    }
    
    /// Sink action - accepts tokens with insurance
    access(all) struct interface InsuredSink: InsuredAction {
        /// Get the vault type this sink accepts
        access(all) view fun getSinkType(): Type
        
        /// Get maximum capacity
        access(all) view fun maximumCapacity(user: Address): UFix64
        
        /// Deposit tokens with insurance protection
        access(FungibleToken.Withdraw) fun depositInsured(
            user: Address,
            vault: @{FungibleToken.Vault}
        ): ActionResult
    }
    
    /// Swapper action - exchanges tokens with insurance
    access(all) struct interface InsuredSwapper: InsuredAction {
        /// Get input token type
        access(all) view fun getInputType(): Type
        
        /// Get output token type
        access(all) view fun getOutputType(): Type
        
        /// Get estimated output amount for given input
        access(all) view fun estimateOutput(inputAmount: UFix64): UFix64
        
        /// Execute swap with insurance protection
        access(FungibleToken.Withdraw) fun swapInsured(
            user: Address,
            inputVault: @{FungibleToken.Vault},
            minOutputAmount: UFix64
        ): @{FungibleToken.Vault}
    }
    
    /// Transfer action - moves tokens with insurance
    access(all) struct interface InsuredTransfer: InsuredAction {
        /// Get token type being transferred
        access(all) view fun getTokenType(): Type
        
        /// Execute transfer with insurance protection
        access(FungibleToken.Withdraw) fun transferInsured(
            from: Address,
            to: Address,
            amount: UFix64
        ): ActionResult
    }
    
    /// Action metadata for discovery
    access(all) struct ActionMetadata {
        access(all) let name: String
        access(all) let description: String
        access(all) let actionType: String
        access(all) let version: String
        access(all) let author: Address
        access(all) let tags: [String]
        
        init(
            name: String,
            description: String,
            actionType: String,
            version: String,
            author: Address,
            tags: [String]
        ) {
            self.name = name
            self.description = description
            self.actionType = actionType
            self.version = version
            self.author = author
            self.tags = tags
        }
    }
    
    /// Action registry for discovery
    access(all) resource interface ActionRegistry {
        /// Register a new action type
        access(all) fun registerAction(metadata: ActionMetadata)
        
        /// Get all registered actions
        access(all) view fun getAllActions(): [ActionMetadata]
        
        /// Search actions by type
        access(all) view fun getActionsByType(actionType: String): [ActionMetadata]
        
        /// Search actions by tag
        access(all) view fun getActionsByTag(tag: String): [ActionMetadata]
    }
}
