import AutoCompound from "../contracts/AutoCompound.cdc"

access(all) fun main(user: Address): AutoCompound.CompoundConfig? {
    return AutoCompound.getConfig(user: user)
}
