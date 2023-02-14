import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

// Migrates the whole collection
transaction(playerId: String, imxWallet: String) {
  let admin: &ChainmonstersRewards.Admin
  let collectionRef: &ChainmonstersRewards.Collection

  prepare(acct: AuthAccount, adminAcct: AuthAccount) {
    // borrow a reference to the owner's collection
    self.collectionRef = acct.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the stored Reward collection")

    // borrow a reference to the admin resource
    self.admin = adminAcct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  }

  execute {
    for id in self.collectionRef.getIDs() {
      let token <- self.collectionRef.withdraw(withdrawID: id)
      self.admin.migrateItem(token: <- token, playerId: playerId, imxWallet: imxWallet)
    }
  }
}
 