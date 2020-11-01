import ChainmonstersNFT from 0xCHAINMONSTERS

// This transaction is what an admin would use to mint a single new NFT
// and deposit it in a user's collection

// Parameters
//
// rewardID: the ID of a reward from which a new NFT is minted
// recipientAddr: the Flow address of the account receiving the newly minted NFT


transaction(rewardID: UInt32, recipientAddr: Address) {
    // local variable for the admin reference
    let adminRef: &ChainmonstersNFT.Admin

    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&ChainmonstersNFT.Admin>(from: /storage/ChainmonstersAdmin)!
    }

    execute {
        // Borrow a reference to the specified reward
        //let rewardRef = self.adminRef.borrowReward(rewardID: rewardID)

        // Mint a new NFT
        let nft1 <- self.adminRef.mintReward(rewardID: rewardID)

        // get the public account object for the recipient
        let recipient = getAccount(recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/RewardCollection)!.borrow<&{ChainmonstersNFT.RewardCollectionPublic}>()
            ?? panic("Cannot borrow a reference to the recipient's reward collection")

        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-nft1)
    }
}