import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"

// Create a product
transaction(
  priceCuts: [ChainmonstersProducts.PriceCut], 
  paymentVaultType: Type, 
  saleEnabled: Bool, 
  totalSupply: UInt32?, 
  saleEndTime: UFix64?, 
  metadata: String?
) {
  let admin: &ChainmonstersProducts.Admin
  
  prepare(acct: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    self.admin = acct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  } 

  execute {
    self.admin.createNewProduct(
      priceCuts: priceCuts,
      paymentVaultType: paymentVaultType,
      saleEnabled: saleEnabled,
      totalSupply: totalSupply, 
      saleEndTime: saleEndTime,
      metadata: metadata
    )
  }
}
