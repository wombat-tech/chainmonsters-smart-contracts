import ChainmonstersMarketplace from "../../contracts/ChainmonstersMarketplace.cdc"

// This transaction configures an account to hold SaleOffer items.

transaction {
    prepare(signer: AuthAccount) {

        // if the account doesn't already have a collection
        if signer.borrow<&ChainmonstersMarketplace.Collection>(from: ChainmonstersMarketplace.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- ChainmonstersMarketplace.createEmptyCollection() as! @ChainmonstersMarketplace.Collection
            
            // save it to the account
            signer.save(<-collection, to: ChainmonstersMarketplace.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&ChainmonstersMarketplace.Collection{ChainmonstersMarketplace.CollectionPublic}>(ChainmonstersMarketplace.CollectionPublicPath, target: ChainmonstersMarketplace.CollectionStoragePath)
        }
    }
}
