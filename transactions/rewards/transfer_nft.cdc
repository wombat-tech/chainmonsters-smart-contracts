import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"

// Parameters:
//
// recipient: The Flow address of the account to receive the NFT.
// withdrawID: The id of the NFT to be transferred

transaction(recipient: Address, withdrawID: UInt64) {

    // local variable for storing the transferred token
    let transferToken: @NonFungibleToken.NFT
    
    prepare(acct: AuthAccount) {

        // borrow a reference to the owner's collection
        let collectionRef = acct.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
            ?? panic("Could not borrow a reference to the stored Reward collection")
        
        // withdraw the NFT
        self.transferToken <- collectionRef.withdraw(withdrawID: withdrawID)
    }

    execute {
        // get the recipient's public account object
        let recipient = getAccount(recipient)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/ChainmonstersRewardCollection).borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()!

        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-self.transferToken)
    }
}
