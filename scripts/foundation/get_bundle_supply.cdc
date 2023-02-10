import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Return the supply of foundation bundles
 */
pub fun main(admin: Address): [Int?] {
  let collection = getAccount(admin)
    .getCapability<&{ChainmonstersFoundation.TiersCollectionPublic}>(/public/cmfBundlesCollection)
    .borrow() ?? panic("Could not borrow bundle collection")

  return [
    collection.collectionSize(tier: ChainmonstersFoundation.Tier.RARE),
    collection.collectionSize(tier: ChainmonstersFoundation.Tier.EPIC),
    collection.collectionSize(tier: ChainmonstersFoundation.Tier.LEGENDARY)
  ]
}
