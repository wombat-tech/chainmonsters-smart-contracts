import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

transaction(amount: UInt64) {
  let adminRef: &ChainmonstersRewards.Admin
  let bundlesCollection: &ChainmonstersFoundation.TiersCollection

  prepare(cmAdmin: AuthAccount) {
    // borrow a reference to the admin's collection
    self.adminRef = cmAdmin.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    self.bundlesCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BundlesCollectionStoragePath) ?? panic("Tier collection missing")
  }

  execute {
    // Provide bundles
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.RARE)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 1, quantity: amount))
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.EPIC)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 2, quantity: amount))
    self.bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: 3, quantity: amount))
  }
}
