import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

transaction(tokens: [UInt64], recipientAddr: Address) {
  let transferCollection: @NonFungibleToken.Collection

  prepare(acct: AuthAccount) {

    let bundlesCollection = acct.borrow<&ChainmonstersFoundation.TiersCollection>(
      from: ChainmonstersFoundation.BundlesCollectionStoragePath
    ) ?? panic("Tier collection missing")
    
    // withdraw the NFTs
    self.transferCollection <- bundlesCollection.borrowCollection(tier: ChainmonstersFoundation.Tier.LEGENDARY)!.batchWithdraw(ids: tokens)
  }

  execute {
    // get the recipient's public account object
    let recipient = getAccount(recipientAddr)

    // get the Collection reference for the receiver
    let receiverRef = 
      recipient.getCapability<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(
        /public/ChainmonstersRewardCollection
      ).borrow() ?? panic("Could not borrow receiver collection")

    // deposit the NFTs in the receivers collection
    receiverRef.batchDeposit(tokens: <-self.transferCollection)
  }
}
