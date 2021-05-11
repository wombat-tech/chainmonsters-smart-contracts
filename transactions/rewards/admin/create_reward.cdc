import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"

// creating a reward and setting the total supply

transaction(metadata: String, totalSupply: UInt32) {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let minter = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        minter.createReward(metadata: metadata, totalSupply: totalSupply)
    }
}
