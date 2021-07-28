import NFTStorefront from "./lib/NFTStorefront.cdc"
import ChainmonstersRewards from "./ChainmonstersRewards.cdc"
import NonFungibleToken from "./lib/NonFungibleToken.cdc"
import FungibleToken from "./lib/FungibleToken.cdc"
import FUSD from "./lib/FUSD.cdc"

pub contract ChainmonstersStorefront {
  pub event ListingAvailable(
    storefrontAddress: Address,
    listingResourceID: UInt64,
    nftID: UInt64,
    price: UFix64
  )

  pub let royaltiesPercentage: UFix64

  pub let royaltiesReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>
  
  pub fun createListing(
    storefront: &NFTStorefront.Storefront,
    rewardsProviderCapability: Capability<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
    fusdVaultCapability: Capability<&FUSD.Vault{FungibleToken.Receiver}>,
    nftID: UInt64,
    price: UFix64
  ) {
    assert(rewardsProviderCapability.borrow()!.borrowNFT(id: nftID) != nil, message: "NFT is not in rewards provider collection")
    
    // Calculate royalties and add cuts for the seller and marketplace
    let royalties = price * self.royaltiesPercentage

    let saleCut = NFTStorefront.SaleCut(
      receiver: fusdVaultCapability,
      amount: price - royalties
    )

    let platformCut = NFTStorefront.SaleCut(
      receiver: self.royaltiesReceiver,
      amount: royalties
    )

    let listingResourceID = storefront.createListing(
      nftProviderCapability: rewardsProviderCapability,
      nftType: Type<@ChainmonstersRewards.NFT>(),
      nftID: nftID,
      salePaymentVaultType: Type<@FUSD.Vault>(),
      saleCuts: [saleCut, platformCut]
    )

    let listing = storefront.borrowListing(listingResourceID: listingResourceID)!

    // We emit a custom ListingAvailable event to track "legit" listings with the correct cuts applied
    emit ListingAvailable(
      storefrontAddress: storefront.owner?.address!,
      listingResourceID: listingResourceID,
      nftID: nftID,
      price: listing.getDetails().salePrice
    )
  }

  init() {
    self.royaltiesPercentage = 0.05
    self.royaltiesReceiver = self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
  }
}
