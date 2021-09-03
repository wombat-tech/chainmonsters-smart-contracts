import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"
import FUSD from "../../../contracts/lib/FUSD.cdc"

// Purchase a product (TEST: No check if product exists and free payment amount)
transaction(productID: UInt32, amount: UFix64) {
  let buyerReceiptCollection: &ChainmonstersProducts.ReceiptCollection
  let mainPayerVault: &FUSD.Vault
  let admin: &ChainmonstersProducts.Admin

  prepare(acct: AuthAccount, adminAcct: AuthAccount) {
    // First, check to see if a receipts collection exists
    if acct.borrow<&ChainmonstersProducts.ReceiptCollection>(from: ChainmonstersProducts.CollectionStoragePath) == nil {
      // create a new collection
      let collection <- ChainmonstersProducts.createReceiptCollection()

      // Put the new collection in storage
      acct.save(<- collection, to: ChainmonstersProducts.CollectionStoragePath)

      // create a public capability for the collection
      acct.link<&ChainmonstersProducts.ReceiptCollection>(ChainmonstersProducts.CollectionPublicPath, target: ChainmonstersProducts.CollectionStoragePath)
    }

    self.buyerReceiptCollection = acct.borrow<&ChainmonstersProducts.ReceiptCollection>(from: ChainmonstersProducts.CollectionStoragePath)!
    self.mainPayerVault = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow FUSD vault");
    self.admin = adminAcct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
  } 

  execute {
    // A payment vault with any amount
    let paymentVault <- self.mainPayerVault.withdraw(amount: amount)

    self.admin.purchase(
      productID: productID, 
      buyerReceiptCollection: self.buyerReceiptCollection, 
      paymentVault: <- paymentVault
    )
  }
}
