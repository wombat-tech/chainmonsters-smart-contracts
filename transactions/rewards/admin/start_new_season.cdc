import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"

// starts a new season
transaction(metadata: String, totalSupply: UInt32) {
    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        let season = admin.startNewSeason()

        log(season)
    }
}
