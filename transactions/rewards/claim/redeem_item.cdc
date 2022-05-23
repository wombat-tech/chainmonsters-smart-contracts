import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import NonFungibleToken from "../../../contracts/lib/NonFungibleToken.cdc"

// Redeem a token to be used ingame
transaction(tokenId: UInt64, playerId: String) {
  let burnToken: @NonFungibleToken.NFT
  let admin: &ChainmonstersRewards.Admin

  prepare(acct: AuthAccount, adminAcct: AuthAccount) {
    assert(playerId.length > 0, message: "Player ID cannot be empty")
    
    // borrow a reference to the owner's collection
    let collectionRef = acct.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the stored Reward collection")
        
    // withdraw the NFT
    self.burnToken <- collectionRef.withdraw(withdrawID: tokenId)

    // borrow a reference to the admin resource
    self.admin = adminAcct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  } 

  execute {
    self.admin.consumeItem(token: <- self.burnToken, playerId: playerId)
  }
}
