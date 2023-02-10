import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

transaction() {
  let adminRef: &ChainmonstersRewards.Admin
  let reservedTiersCollection: &ChainmonstersFoundation.TiersCollection
  let bonusTiersCollection: &ChainmonstersFoundation.TiersCollection

  prepare(cmAdmin: AuthAccount) {
    // borrow a reference to the admin's collection
    self.adminRef = cmAdmin.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    self.reservedTiersCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.ReservedTiersCollectionStoragePath) ?? panic("Tier collection missing")
    self.bonusTiersCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BonusTiersCollectionStoragePath) ?? panic("Tier collection missing")
  }

  execute {
    // Provide reserved items
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 1, quantity: 5))
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 2, quantity: 5))
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 3, quantity: 4))

    // Provide bonus items
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 1, quantity: 5))
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 2, quantity: 4))
    self.bonusTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 3, quantity: 1))
  }
}
