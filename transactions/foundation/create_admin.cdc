import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Delete all account storage
 */
transaction {
  let admin: &ChainmonstersFoundation.Admin

  prepare(admin: AuthAccount, newAdmin: AuthAccount) {
    self.admin = admin.borrow<&ChainmonstersFoundation.Admin>(
      from: ChainmonstersFoundation.AdminStoragePath
    ) ?? panic("Could not borrow admin resource")

    newAdmin.save<@ChainmonstersFoundation.Admin>(
      <- self.admin.createNewAdmin(),
      to: ChainmonstersFoundation.AdminStoragePath
    )
  }
}
