import ScheduledTransfer from 0x8401ed4fc6788c8a

access(all) fun main(addr: Address): Bool {
  let account = getAccount(addr)
  return account.storage.check<@AnyResource>(from: ScheduledTransfer.HandlerStoragePath)
}
