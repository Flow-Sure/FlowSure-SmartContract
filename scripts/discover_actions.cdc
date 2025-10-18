import "FlowSureActions"
import "IFlowSureAction"

/// Discover all available Flow Actions in FlowSure
access(all) fun main(): {String: ActionInfo} {
    let actions = FlowSureActions.getRegisteredActions()
    let actionInfo: {String: ActionInfo} = {}
    
    for key in actions.keys {
        let metadata = actions[key]!
        actionInfo[key] = ActionInfo(
            name: metadata.name,
            description: metadata.description,
            actionType: metadata.actionType,
            version: metadata.version,
            author: metadata.author.toString(),
            tags: metadata.tags
        )
    }
    
    return actionInfo
}

access(all) struct ActionInfo {
    access(all) let name: String
    access(all) let description: String
    access(all) let actionType: String
    access(all) let version: String
    access(all) let author: String
    access(all) let tags: [String]
    
    init(
        name: String,
        description: String,
        actionType: String,
        version: String,
        author: String,
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
