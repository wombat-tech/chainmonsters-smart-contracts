import ChainmonstersNFT from 0xCHAINMONSTERS

// This transaction sets up an account to use Chainmonsters
// by storing an empty NFT collection and creating
// a public capability for it

transaction {

    prepare(acct: AuthAccount) {

        // First, check to see if an NFT collection already exists
        if acct.borrow<&ChainmonstersNFT.Collection>(from: /storage/RewardCollection) == nil {

            // create a new Chainmonsters Collection
            let collection <- ChainmonstersNFT.createEmptyCollection() as! @ChainmonstersNFT.Collection

            // Put the new Collection in storage
            acct.save(<-collection, to: /storage/RewardCollection)

            // create a public capability for the collection
            acct.link<&{ChainmonstersNFT.RewardCollectionPublic}>(/public/RewardCollection, target: /storage/RewardCollection)
        }
    }
}
