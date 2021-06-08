import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersMarketplace from "../../contracts/ChainmonstersMarketplace.cdc"

transaction(itemID: UInt64, price: UFix64) {
    let fusdVault: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let ChainmonstersRewardsCollection: Capability<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>
    let marketCollection: &ChainmonstersMarketplace.Collection

    prepare(signer: AuthAccount) {
        // we need a provider capability, but one is not provided by default so we create one.
        let ChainmonstersRewardsCollectionProviderPrivatePath = /private/ChainmonstersRewardsCollectionProvider

        self.fusdVault = signer.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
        assert(self.fusdVault.borrow() != nil, message: "Missing or mis-typed FUSD receiver")

        if !signer.getCapability<&ChainmonstersRewards.Collection>(ChainmonstersRewardsCollectionProviderPrivatePath).check() {
            signer.link<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(ChainmonstersRewardsCollectionProviderPrivatePath, target: /storage/ChainmonstersRewardCollection)
        }

        self.ChainmonstersRewardsCollection = signer.getCapability<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(ChainmonstersRewardsCollectionProviderPrivatePath)
        assert(self.ChainmonstersRewardsCollection.borrow() != nil, message: "Missing or mis-typed ChainmonstersRewardsCollection provider")

        self.marketCollection = signer.borrow<&ChainmonstersMarketplace.Collection>(from: ChainmonstersMarketplace.CollectionStoragePath)
            ?? panic("Missing or mis-typed ChainmonstersMarketplace Collection")
    }

    execute {
        let offer <- ChainmonstersMarketplace.createSaleOffer (
            sellerItemProvider: self.ChainmonstersRewardsCollection,
            saleItemID: itemID,
            sellerPaymentReceiver: self.fusdVault,
            marketFeeReceiver: self.fusdVault,
            salePrice: price
        )
        self.marketCollection.insert(offer: <-offer)
    }
}
