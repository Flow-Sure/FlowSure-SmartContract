import "NonFungibleToken"
import "MetadataViews"

// Generic script to fetch ALL NFTs from a user's account on testnet
access(all) fun main(address: Address): {String: [AnyStruct]} {
  let account = getAccount(address)
  var nftCollections: {String: [AnyStruct]} = {}
  
  // Iterate through all storage paths to find NFT collections
  account.storage.forEachStored(fun (path: StoragePath, type: Type): Bool {
    // Check if this is an NFT collection
    if type.isSubtype(of: Type<@{NonFungibleToken.Collection}>()) {
      if let collectionRef = account.storage.borrow<&{NonFungibleToken.Collection}>(from: path) {
        let ids = collectionRef.getIDs()
        
        if ids.length > 0 {
          var nfts: [AnyStruct] = []
          
          for id in ids {
            if let nft = collectionRef.borrowNFT(id) {
              var nftData: {String: AnyStruct} = {
                "id": id,
                "type": nft.getType().identifier,
                "uuid": nft.uuid
              }
              
              // Try to get MetadataViews.Display
              if let display = nft.resolveView(Type<MetadataViews.Display>()) as? MetadataViews.Display {
                nftData["name"] = display.name
                nftData["description"] = display.description
                nftData["thumbnail"] = display.thumbnail.uri()
              }
              
              // Try to get NFTCollectionData
              if let collectionData = nft.resolveView(Type<MetadataViews.NFTCollectionData>()) as? MetadataViews.NFTCollectionData {
                nftData["collectionName"] = collectionData.collectionName
                nftData["collectionDescription"] = collectionData.collectionDescription
              }
              
              nfts.append(nftData)
            }
          }
          
          nftCollections[path.toString()] = nfts
        }
      }
    }
    
    return true
  })
  
  return nftCollections
}
