import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"
import FlowToken from "../../../contracts/lib/FlowToken.cdc"

// Purchase a product
transaction(productID: UInt32) {
  let buyerReceiptCollection: &ChainmonstersProducts.ReceiptCollection
  let mainPayerVault: &FlowToken.Vault

  prepare(acct: AuthAccount) {
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
    self.mainPayerVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow FLOW vault");
  } 

  execute {
    let product = ChainmonstersProducts.getProduct(productID: productID) ?? panic("Product not found")
    let paymentVault <- self.mainPayerVault.withdraw(amount: product.price)

    ChainmonstersProducts.purchase(
      productID: productID, 
      buyerReceiptCollection: self.buyerReceiptCollection, 
      paymentVault: <- paymentVault
    )
  }
}
