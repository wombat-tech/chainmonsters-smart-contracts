import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"

// This transaction mints multiple nfts from a single reward 

transaction(rewardID: UInt32, quantity: UInt64, recipientAddr: Address) {

    // Local variable for the topshot Admin object
    let adminRef: &ChainmonstersRewards.Admin

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)!
    }

    execute {

        // Mint all the new NFTs
        let collection <- self.adminRef.batchMintReward(rewardID: rewardID, quantity: quantity)

        // Get the account object for the recipient of the minted tokens
        let recipient = getAccount(recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/ChainmonstersRewardCollection)!.borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()
            ?? panic("Cannot borrow a reference to the recipient's reward collection")

        // deposit the NFT in the receivers collection
        receiverRef.batchDeposit(tokens: <-collection)
    }
}
