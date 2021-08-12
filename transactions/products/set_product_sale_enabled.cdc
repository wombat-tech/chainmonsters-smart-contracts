import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"

// Create a product
transaction(productID: UInt32, saleEnabled: Bool) {
  let admin: &ChainmonstersProducts.Admin
  
  prepare(acct: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    self.admin = acct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  } 

  execute {
    self.admin.setProductSaleEnabled(productID: productID, saleEnabled: saleEnabled)
  }
}
