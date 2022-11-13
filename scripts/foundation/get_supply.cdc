
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Return the supply of foundation NFTS
 */
pub fun main(admin: Address): [Int?] {
  let bundlesCollection = getAuthAccount(admin).borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BundlesCollectionStoragePath) ?? panic("Tier collection missing")
  let reservedTiersCollection = getAuthAccount(admin).borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.ReservedTiersCollectionStoragePath) ?? panic("Tier collection missing")
  let bonusTiersCollection = getAuthAccount(admin).borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BonusTiersCollectionStoragePath) ?? panic("Tier collection missing")

  return [
    bundlesCollection.collectionSize(tier: ChainmonstersFoundation.Tier.RARE),
    bundlesCollection.collectionSize(tier: ChainmonstersFoundation.Tier.EPIC),
    bundlesCollection.collectionSize(tier: ChainmonstersFoundation.Tier.LEGENDARY),
    reservedTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.RARE),
    reservedTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.EPIC),
    reservedTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.LEGENDARY),
    bonusTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.RARE),
    bonusTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.EPIC),
    bonusTiersCollection.collectionSize(tier: ChainmonstersFoundation.Tier.LEGENDARY)
  ]
}
