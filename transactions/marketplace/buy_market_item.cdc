import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersMarketplace from "../../contracts/ChainmonstersMarketplace.cdc"

transaction(saleItemID: UInt64, marketCollectionAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let rewardsCollection: &ChainmonstersRewards.Collection{NonFungibleToken.Receiver}
    let marketCollection: &ChainmonstersMarketplace.Collection{ChainmonstersMarketplace.CollectionPublic}

    prepare(signer: AuthAccount) {
        self.marketCollection = getAccount(marketCollectionAddress)
            .getCapability(ChainmonstersMarketplace.CollectionPublicPath)
            .borrow<&ChainmonstersMarketplace.Collection{ChainmonstersMarketplace.CollectionPublic}>()
            ?? panic("Could not borrow market collection from market address")

        let saleItem = self.marketCollection.borrowSaleItem(saleItemID: saleItemID)
                    ?? panic("No item with that ID")
        let salePrice = saleItem.salePrice

        let mainFUSDVault = signer.borrow<&FungibleToken.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from acct storage")
        self.paymentVault <- mainFUSDVault.withdraw(amount: salePrice)

        self.rewardsCollection = signer.borrow<&ChainmonstersRewards.Collection{NonFungibleToken.Receiver}>(
            from: /storage/ChainmonstersRewardCollection
        ) ?? panic("Cannot borrow rewards collection receiver from acct")
    }

    execute {
        self.marketCollection.purchase(
            saleItemID: saleItemID,
            buyerCollection: self.rewardsCollection,
            buyerPayment: <- self.paymentVault
        )
    }
}
