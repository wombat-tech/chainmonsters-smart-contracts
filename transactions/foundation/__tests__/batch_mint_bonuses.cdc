import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

transaction(rawTier: UInt8, rewardID: UInt32, quantity: UInt64) {
  let adminRef: &ChainmonstersRewards.Admin
  let reservedTiersCollection: &ChainmonstersFoundation.TiersCollection

  prepare(cmAdmin: AuthAccount) {
    // borrow a reference to the admin's collection
    self.adminRef = cmAdmin.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    self.reservedTiersCollection = cmAdmin.borrow<&ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BonusTiersCollectionStoragePath) ?? panic("Tier collection missing")
  }

  execute {
    // Provide reserved items
    self.reservedTiersCollection.borrowCollection(tier: ChainmonstersFoundation.Tier(rawValue: rawTier)!)!
      .batchDeposit(tokens: <- self.adminRef.batchMintReward(rewardID: rewardID, quantity: quantity))
  }
}

// Result: [14000, 4000, 2250, 46002, 4500, 2500, 0, 500, 500]
