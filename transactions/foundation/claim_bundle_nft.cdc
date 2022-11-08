import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"

transaction(nftID: UInt64, bundleRewardIds: [UInt32]) {
  let adminCollectionRef: &ChainmonstersRewards.Collection
  let userCollectionRef: &ChainmonstersRewards.Collection
  let nftToBeClaimed: @NonFungibleToken.NFT
  var wonNFTs: [UInt64]

  prepare(cmAdmin: AuthAccount, user: AuthAccount) {
    // borrow a reference to the user's collection
    self.userCollectionRef = user.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the user's stored Rewards collection")

    // borrow a reference to the admin's collection
    self.adminCollectionRef = cmAdmin.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the admin's stored Rewards collection")

    // withdraw reference to the user's NFT
    self.nftToBeClaimed <- self.userCollectionRef.withdraw(withdrawID: nftID)

    self.wonNFTs = []
  }

  pre {
    bundleRewardIds.length == 3: "Need to specify 3 bundle reward ids"
  }

  execute {
    // Burn the user's NFT
    destroy self.nftToBeClaimed

    // TODO: Raffle NFTs
    let ownedNFTs = self.adminCollectionRef.getIDs()
    self.wonNFTs = [ownedNFTs[0], ownedNFTs[1], ownedNFTs[2]]

    // Deposit the claimed NFTs into the user's collection
    self.userCollectionRef.batchDeposit(tokens: <- self.adminCollectionRef.batchWithdraw(ids: self.wonNFTs))
  }

  post {
    self.userCollectionRef.ownedNFTs[nftID] == nil: "The NFT should no longer exist in the user's collection"
  }
}
