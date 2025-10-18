import "HybridCustody"
import "NonFungibleToken"
import "MetadataViews"
import "TopShot"
import "AllDay"

// Fetch NFTs from linked accounts (e.g., Dapper Wallet linked to Flow Wallet)
access(all) fun main(addr: Address): AnyStruct {
  let manager = getAuthAccount<auth(Storage) &Account>(addr).storage.borrow<auth(HybridCustody.Manage) &HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
    ?? panic("manager does not exist")

  var nftData: {Address: {String: [AnyStruct]}} = {}
  let providerType = Type<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider}>()

  // Iterate through all linked child accounts
  for address in manager.getChildAddresses() {
    let acct = getAuthAccount<auth(Storage, Capabilities) &Account>(address)
    let childAcct = manager.borrowAccount(addr: address) ?? panic("child account not found")
    
    var accountNFTs: {String: [AnyStruct]} = {}
    
    // Check for TopShot collection
    for s in acct.storage.storagePaths {
      for c in acct.capabilities.storage.getControllers(forPath: s) {
        if !c.borrowType.isSubtype(of: providerType) {
          continue
        }
        
        if let cap: Capability = childAcct.getCapability(controllerID: c.capabilityID, type: providerType) {
          let providerCap = cap as! Capability<&{NonFungibleToken.Provider}>
          
          if !providerCap.check() {
            continue
          }
          
          let typeId = cap.borrow<&AnyResource>()!.getType().identifier
          
          // Check if it's TopShot
          if typeId.contains("TopShot") {
            if let collection = acct.storage.borrow<&{TopShot.MomentCollectionPublic}>(from: /storage/MomentCollection) {
              var moments: [AnyStruct] = []
              for id in collection.getIDs() {
                if let moment = collection.borrowMoment(id: id) {
                  let metadata = TopShot.getPlayMetaData(playID: moment.data.playID) ?? {}
                  if let display = moment.resolveView(Type<MetadataViews.Display>()) as? MetadataViews.Display {
                    moments.append({
                      "id": id,
                      "playID": moment.data.playID,
                      "setID": moment.data.setID,
                      "serialNumber": moment.data.serialNumber,
                      "playerName": metadata["FullName"] ?? "Unknown",
                      "teamAtMoment": metadata["TeamAtMoment"] ?? "Unknown",
                      "playCategory": metadata["PlayCategory"] ?? "Unknown",
                      "name": display.name,
                      "description": display.description,
                      "thumbnail": display.thumbnail.uri(),
                      "type": "NBA Top Shot"
                    })
                  }
                }
              }
              accountNFTs["TopShot"] = moments
            }
          }
          
          // Check if it's AllDay
          if typeId.contains("AllDay") {
            if let collection = acct.storage.borrow<&{AllDay.MomentNFTCollectionPublic}>(from: /storage/AllDayNFTCollection) {
              var moments: [AnyStruct] = []
              for id in collection.getIDs() {
                if let moment = collection.borrowMomentNFT(id: id) {
                  let metadata = AllDay.getPlayMetaData(playID: moment.data.playID) ?? {}
                  if let display = moment.resolveView(Type<MetadataViews.Display>()) as? MetadataViews.Display {
                    moments.append({
                      "id": id,
                      "playID": moment.data.playID,
                      "setID": moment.data.setID,
                      "serialNumber": moment.data.serialNumber,
                      "playerName": metadata["PlayerFirstName"] ?? "Unknown",
                      "teamAtMoment": metadata["PlayerKnownName"] ?? "Unknown",
                      "playCategory": metadata["PlayType"] ?? "Unknown",
                      "name": display.name,
                      "description": display.description,
                      "thumbnail": display.thumbnail.uri(),
                      "type": "NFL All Day"
                    })
                  }
                }
              }
              accountNFTs["AllDay"] = moments
            }
          }
        }
      }
    }
    
    if accountNFTs.length > 0 {
      nftData[address] = accountNFTs
    }
  }
  
  return nftData
}
