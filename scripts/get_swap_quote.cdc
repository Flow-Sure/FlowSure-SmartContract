import "FlowToken"
import "IncrementFiConnector"

/// Get a swap quote from IncrementFi
/// Returns estimated output amount for given input
access(all) fun main(amountIn: UFix64): SwapQuote {
    let tokenIn = Type<@FlowToken.Vault>()
    let tokenOut = Type<@FlowToken.Vault>()
    
    // Check if pair exists
    let pairExists = IncrementFiConnector.pairExists(
        tokenA: tokenIn,
        tokenB: tokenOut
    )
    
    if !pairExists {
        return SwapQuote(
            inputAmount: amountIn,
            outputAmount: 0.0,
            priceImpact: 0.0,
            tradingFee: 0.0,
            minimumReceived: 0.0,
            pairExists: false,
            route: []
        )
    }
    
    // Get quote
    let outputAmount = IncrementFiConnector.getSwapQuote(
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        amountIn: amountIn
    )
    
    // Calculate metrics
    let tradingFee = amountIn * 0.003 // 0.3% for volatile pairs
    let priceImpact = ((amountIn - outputAmount) / amountIn) * 100.0
    let slippage = 0.5 // 0.5% slippage tolerance
    let minimumReceived = outputAmount * (1.0 - (slippage / 100.0))
    
    return SwapQuote(
        inputAmount: amountIn,
        outputAmount: outputAmount,
        priceImpact: priceImpact,
        tradingFee: tradingFee,
        minimumReceived: minimumReceived,
        pairExists: true,
        route: ["FLOW", "USDC"] // Example route
    )
}

access(all) struct SwapQuote {
    access(all) let inputAmount: UFix64
    access(all) let outputAmount: UFix64
    access(all) let priceImpact: UFix64
    access(all) let tradingFee: UFix64
    access(all) let minimumReceived: UFix64
    access(all) let pairExists: Bool
    access(all) let route: [String]
    
    init(
        inputAmount: UFix64,
        outputAmount: UFix64,
        priceImpact: UFix64,
        tradingFee: UFix64,
        minimumReceived: UFix64,
        pairExists: Bool,
        route: [String]
    ) {
        self.inputAmount = inputAmount
        self.outputAmount = outputAmount
        self.priceImpact = priceImpact
        self.tradingFee = tradingFee
        self.minimumReceived = minimumReceived
        self.pairExists = pairExists
        self.route = route
    }
}
