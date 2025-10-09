import InsuredAction from "../contracts/InsuredAction.cdc"

access(all) fun main(actionId: String): InsuredAction.ActionRecord? {
    let actionManagerRef = InsuredAction.borrowActionManager()
    return actionManagerRef.getActionRecord(actionId: actionId)
}
