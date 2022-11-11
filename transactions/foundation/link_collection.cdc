import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Create a public link for bundles collection if it doesn't exist yet
 */
transaction {
  prepare(admin: AuthAccount) {
    if (!admin.getCapability<&{ChainmonstersFoundation.TiersCollectionPublic}>(/public/cmfBundlesCollection).check()) {
      admin.link<&{ChainmonstersFoundation.TiersCollectionPublic}>(
        /public/cmfBundlesCollection,
        target: ChainmonstersFoundation.BundlesCollectionStoragePath
      )
    }
  }
}
