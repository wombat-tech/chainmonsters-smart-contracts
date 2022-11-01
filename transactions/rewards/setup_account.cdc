import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import MetadataViews from "../../contracts/lib/MetadataViews.cdc"

/// This transaction is what an account would run
/// to set itself up to receive NFTs
transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection) != nil {
            return
        }

        // Create a new empty collection
        let collection <- ChainmonstersRewards.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: /storage/ChainmonstersRewardCollection)

        // create a public capability for the collection
        signer.link<&{NonFungibleToken.CollectionPublic, ChainmonstersRewards.ChainmonstersRewardCollectionPublic, MetadataViews.ResolverCollection}>(
            /public/ChainmonstersRewardCollection,
            target: /storage/ChainmonstersRewardCollection
        )
    }
}
