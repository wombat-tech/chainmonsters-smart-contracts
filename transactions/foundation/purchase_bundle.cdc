import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * This transaction allows to purchase an NFT with the given tier for a specific price and currency.
 */
transaction(
  rawTier: UInt8,
  price: UFix64,
  receiver: Address,
  fungibleTokenVaultStoragePath: StoragePath,
  fungibleTokenReceiverPublicPath: PublicPath
) {
  let paymentVault: @FungibleToken.Vault
  let sellerPaymentReceiver: &{FungibleToken.Receiver}

  let foundationAdminRef: &ChainmonstersFoundation.Admin
  let buyerRewardsCollection: &ChainmonstersRewards.Collection
  var purchasedTokenId: UInt64?

  prepare(cmAdmin: AuthAccount, buyer: AuthAccount) {
    let buyerVault = buyer
      .borrow<&FungibleToken.Vault>(from: fungibleTokenVaultStoragePath)
      ?? panic("Could not borrow reference to buyer vault")

    // Withdraw the payment amount from the buyer vault
    self.paymentVault <- buyerVault.withdraw(amount: price)

    // Borrow reference to the payment receiver
    self.sellerPaymentReceiver = getAccount(receiver)
      .getCapability<&{FungibleToken.Receiver}>(fungibleTokenReceiverPublicPath)
      .borrow() ?? panic("Could not borrow reference to receiver vault")

    // Borrow reference to the ChainmonstersFoundation admin resource
    self.foundationAdminRef = cmAdmin
      .borrow<&ChainmonstersFoundation.Admin>(from: ChainmonstersFoundation.AdminStoragePath)
      ?? panic("Could not borrow reference to ChainmonstersFoundation admin")

    // Check for ChainmonstersRewards collection and create one if needed
    if buyer.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection) == nil {
      // Create a new ChainmonstersRewards collection
      let collection <- ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection
      // Put the new Collection in storage
      buyer.save(<-collection, to: /storage/ChainmonstersRewardCollection)
      // Create a public capability for the collection
      buyer.link<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection, target: /storage/ChainmonstersRewardCollection)
    }

    // Borrow reference to the ChainmonstersRewards collection
    self.buyerRewardsCollection = buyer.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)!

    // Initialize empty purchasedTokenId for post-transaction sanity check
    self.purchasedTokenId = nil
  }

  execute {
    let tier = ChainmonstersFoundation.Tier(rawValue: rawTier) ?? panic("Invalid tier")

    // Transfer fungible tokens to seller
    self.sellerPaymentReceiver.deposit(from: <- self.paymentVault)

    // Purchase NFT
    let token <- self.foundationAdminRef.sellBundle(tier: tier)

    // Update purchasedTokenId with newly minted NFT id
    self.purchasedTokenId = token.id

    // Transfer NFT to buyer
    self.buyerRewardsCollection.deposit(token: <- token)
  }

  post {
    self.buyerRewardsCollection.borrowReward(id: self.purchasedTokenId!) != nil: "NFT not deposited"
  }
}
