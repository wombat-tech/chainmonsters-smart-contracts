import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/lib/MetadataViews.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

/**
 * This transaction allows to purchase an NFT with the given rewardID for a specific price.
 */
transaction() {
  let userCollection: &{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}
  let freeClaimTracker: [Address]
  let userAddress: Address
  let nftToClaim: @NonFungibleToken.NFT
  let admin: AuthAccount

  prepare(cmAdmin: AuthAccount, user: AuthAccount) {
    // Create new Rewards collection if user doesn't have one yet
    if user.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection) == nil {
      let collection <- ChainmonstersRewards.createEmptyCollection()

      user.save(<-collection, to: /storage/ChainmonstersRewardCollection)

      user.link<&{NonFungibleToken.CollectionPublic, ChainmonstersRewards.ChainmonstersRewardCollectionPublic, MetadataViews.ResolverCollection}>(
        /public/ChainmonstersRewardCollection,
        target: /storage/ChainmonstersRewardCollection
      )
    }

    // Get public interface for the user's collection
    self.userCollection = user.getCapability<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection).borrow()!

    // Get the user's address
    self.userAddress = user.address

    // Get the free claim tracker array
    self.freeClaimTracker = cmAdmin.load<[Address]>(from: /storage/freeClaimTracker) ?? []

    let adminCollection = cmAdmin.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection) ?? panic("Could not borrow admin collection")

    let ids = adminCollection.getIDs()

    assert(ids.length > 0, message: "No free claim rewards available")

    // Withdraw the NFT from the admin collection
    self.nftToClaim <- adminCollection.withdraw(withdrawID: ids[0])

    // Get a reference to the admin
    self.admin = cmAdmin
  }

  pre {
    !self.freeClaimTracker.contains(self.userAddress): "User has already claimed a free reward"
  }

  execute {
    // Deposit the NFT in the user's collection
    self.userCollection.deposit(token: <- self.nftToClaim)

    // Add user's address to the free claim tracker
    self.freeClaimTracker.append(self.userAddress)

    // Save the free claim tracker
    self.admin.save(self.freeClaimTracker, to: /storage/freeClaimTracker)
  }

  post {
    self.freeClaimTracker.contains(self.userAddress): "User has not been saved to the tracker"
  }
}
