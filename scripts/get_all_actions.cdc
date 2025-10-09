import InsuredAction from "../contracts/InsuredAction.cdc"

access(all) fun main(): [InsuredAction.ActionRecord] {
    let actionManagerRef = InsuredAction.borrowActionManager()
    return actionManagerRef.getAllActionRecords()
}
