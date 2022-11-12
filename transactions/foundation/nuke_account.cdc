import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Delete all account storage
 */
transaction {
  let bundlesCollection: @ChainmonstersFoundation.TiersCollection?
  let reservedCollection: @ChainmonstersFoundation.TiersCollection?
  let bonusCollection: @ChainmonstersFoundation.TiersCollection?
  let admin: @ChainmonstersFoundation.Admin?
  let acc: AuthAccount

  prepare(admin: AuthAccount) {
    self.bundlesCollection <- admin.load<@ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BundlesCollectionStoragePath)
    self.reservedCollection <- admin.load<@ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.ReservedTiersCollectionStoragePath)
    self.bonusCollection <- admin.load<@ChainmonstersFoundation.TiersCollection>(from: ChainmonstersFoundation.BonusTiersCollectionStoragePath)
    self.admin <- admin.load<@ChainmonstersFoundation.Admin>(from: ChainmonstersFoundation.AdminStoragePath)

    self.acc = admin
  }

  execute {
    destroy self.bundlesCollection
    destroy self.reservedCollection
    destroy self.bonusCollection
    destroy self.admin

    self.acc.contracts.remove(name: "ChainmonstersFoundation")
  }
}
