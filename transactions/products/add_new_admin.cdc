import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"

// Gives a new account an admin resource to manage the contract
transaction() {
  prepare(acct: AuthAccount, newAdmin: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    let admin = acct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")

    newAdmin.save(<- admin.createNewAdmin(), to: /storage/chainmonstersProductsAdmin)
  } 
}
