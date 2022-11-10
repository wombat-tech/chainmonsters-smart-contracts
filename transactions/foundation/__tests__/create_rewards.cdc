import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"

transaction {
  prepare(acct: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    let admin = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")

    // Create Bundles
    admin.createReward(metadata: "Bundle RARE", totalSupply: 10)
    admin.createReward(metadata: "Bundle EPIC", totalSupply: 10)
    admin.createReward(metadata: "Bundle LEGENDARY", totalSupply: 10)

    // Create Items
    admin.createReward(metadata: "Item RARE", totalSupply: 100)
    admin.createReward(metadata: "Item EPIC", totalSupply: 100)
    admin.createReward(metadata: "Item LEGENDARY", totalSupply: 100)
  }
}
