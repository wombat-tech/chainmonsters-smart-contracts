import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

// Claim tokens to be minted
transaction(playerId: String, items: [[AnyStruct]]) {
  let admin: &ChainmonstersRewards.Admin
  let collectionRef: &ChainmonstersRewards.Collection

  prepare(acct: AuthAccount, adminAcct: AuthAccount) {
    assert(items.length > 0, message: "You must specify at least one item to claim.")
    // borrow a reference to the owner's collection
    self.collectionRef = acct.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the stored Reward collection")

    // borrow a reference to the admin resource
    self.admin = adminAcct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  } 

  execute {
    for item in items {
      let rewardID = item[0] as! UInt32
      let uid = item[1] as! String

      self.collectionRef.deposit(token: <- self.admin.claimItem(rewardID: rewardID, playerId: playerId, uid: uid))
    }
  }
}
