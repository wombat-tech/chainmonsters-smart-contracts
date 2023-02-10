import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"

transaction(nftID: UInt64) {
  let foundationAdminRef: &ChainmonstersFoundation.Admin
  let userCollectionRef: &ChainmonstersRewards.Collection

  prepare(cmAdmin: AuthAccount, user: AuthAccount) {
    // borrow a reference to the user's collection
    self.userCollectionRef = user.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the user's stored Rewards collection")

    // Borrow reference to the ChainmonstersFoundation admin resource
    self.foundationAdminRef = cmAdmin
      .borrow<&ChainmonstersFoundation.Admin>(from: ChainmonstersFoundation.AdminStoragePath)
      ?? panic("Could not borrow reference to ChainmonstersFoundation admin")
  }

  pre {
    self.userCollectionRef.borrowNFT(id: nftID) != nil: "NFT does not exist in the user's collection"
    ChainmonstersFoundation.getTierFromBundleRewardID(rewardID: self.userCollectionRef.borrowReward(id: nftID)!.data!.rewardID!) != nil: "Reward is not a bundle"
  }

  execute {
    // Withdraw bundle NFT
    let bundleNFT <- self.userCollectionRef.withdraw(withdrawID: nftID) as! @ChainmonstersRewards.NFT

    // Burn bundle and raffle items
    let tokens <- self.foundationAdminRef.redeemBundle(nft: <- bundleNFT)

    // Deposit the redeemed NFTs into the user's collection
    self.userCollectionRef.batchDeposit(tokens: <- tokens)
  }

  post {
    self.userCollectionRef.ownedNFTs[nftID] == nil: "The NFT should no longer exist in the user's collection"
  }
}
