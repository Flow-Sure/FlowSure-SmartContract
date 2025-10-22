import ScheduledTransfer from 0xfe1ad3a05230e532
import FlowToken from 0x7e60df042a9c0868

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let account = getAccount(userAddress)
    
    // Check if handler exists
    let hasHandler = account.storage.check<@AnyResource>(from: ScheduledTransfer.HandlerStoragePath)
    
    if !hasHandler {
        return {
            "hasHandler": false,
            "message": "No handler found"
        }
    }
    
    // Try to borrow the handler to check its properties
    if let handlerRef = account.storage.borrow<&AnyResource>(from: ScheduledTransfer.HandlerStoragePath) {
        return {
            "hasHandler": true,
            "handlerType": handlerRef.getType().identifier,
            "message": "Handler exists but we cannot access its internal vault capability from a script"
        }
    }
    
    return {
        "hasHandler": true,
        "message": "Handler exists"
    }
}
