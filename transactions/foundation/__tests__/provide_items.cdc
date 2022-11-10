import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

transaction(amount: UInt64) {
  let adminRef: &ChainmonstersRewards.Admin
  let bundlesCollection: &ChainmonstersFoundation.TiersCollection
  let reservedTiersCollection: &ChainmonstersFoundation.TiersCollection
  let bonusTiersCollection: &ChainmonstersFoundation.TiersCollection

  prepare(cmAdmin: AuthAccount) {
    // borrow a reference to the admin's collection
    self.adminRef = cmAdmin.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    self.bundlesCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BundlesCollectionStoragePath) ?? panic("Tier collection missing")
    self.reservedTiersCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.ReservedTiersCollectionStoragePath) ?? panic("Tier collection missing")
    self.bonusTiersCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BonusTiersCollectionStoragePath) ?? panic("Tier collection missing")
  }

  execute {
    // Provide bundles
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 1, quantity: amount))
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 2, quantity: amount))
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 3, quantity: amount))

    // We always need twice as many items as bundles 
    // @TODO Optimize this
    let itemsAmount = amount * 2;

    // Provide reserved items
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 4, quantity: itemsAmount))
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 5, quantity: itemsAmount))
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 6, quantity: itemsAmount))

    // Provide bonus items
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 4, quantity: itemsAmount))
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 5, quantity: itemsAmount))
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 6, quantity: itemsAmount))
  }
}
