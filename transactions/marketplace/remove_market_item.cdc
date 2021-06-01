import ChainmonstersMarketplace from "../../contracts/ChainmonstersMarketplace.cdc"

transaction(itemID: UInt64) {
    let marketCollection: &ChainmonstersMarketplace.Collection

    prepare(signer: AuthAccount) {
        self.marketCollection = signer
            .borrow<&ChainmonstersMarketplace.Collection>(from: ChainmonstersMarketplace.CollectionStoragePath)
            ?? panic("Missing or mis-typed ChainmonstersMarketplace Collection")
    }

    execute {
        let offer <-self.marketCollection.remove(saleItemID: itemID)
        destroy offer
    }
}
