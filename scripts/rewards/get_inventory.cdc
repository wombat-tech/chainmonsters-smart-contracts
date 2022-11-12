import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import MetadataViews from "../../contracts/lib/MetadataViews.cdc"

pub struct NFT {
  pub let id: UInt64
  pub let rewardID: UInt32
  pub let name: String
  pub let description: String
  pub let thumbnail: String

  init(
    id: UInt64,
    rewardID: UInt32,
    name: String,
    description: String,
    thumbnail: String,
  ) {
    self.id = id
    self.rewardID = rewardID
    self.name = name
    self.description = description
    self.thumbnail = thumbnail
  }
}

pub fun main(address: Address): [NFT] {
  let collection = getAccount(address)
    .getCapability<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection)
    .borrow()

  if (collection == nil) {
    return []
  }

  var nfts: [NFT] = []

  for id in collection!.getIDs() {
    let nft = collection!.borrowReward(id: id)!

    let display = MetadataViews.getDisplay(nft)!

    nfts.append(NFT(
      id: id,
      rewardID: nft.data.rewardID,
      name: display.name,
      description: display.description,
      thumbnail: display.thumbnail.uri()
    ))
  }

  return nfts
}