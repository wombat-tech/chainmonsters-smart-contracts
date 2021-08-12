import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"

// updates reward metadata after contract update

transaction(rewardID: UInt32, metadata: String) {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        admin.updateRewardMetadata(rewardID: rewardID, metadata: metadata)
    }
}
