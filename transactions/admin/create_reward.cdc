import ChainmonstersNFT from 0xCHAINMONSTERS

// creating a reward and setting the total supply

transaction() {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let minter = acct.borrow<&ChainmonstersNFT.Admin>(from: /storage/ChainmonstersAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        minter.createReward(metadata: %s, totalSupply: %t)
    }
}
