import InsuredAction from "../contracts/InsuredAction.cdc"

access(all) fun main(): {String: UInt64} {
    return InsuredAction.getStats()
}
