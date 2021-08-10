import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"
import FUSD from "../../../contracts/lib/FUSD.cdc"

// Try some receipt collection manipulations
transaction() {
  let receiptCollection: &ChainmonstersProducts.ReceiptCollection

  prepare(acct: AuthAccount) {
    self.receiptCollection = acct.borrow<&ChainmonstersProducts.ReceiptCollection>(from: ChainmonstersProducts.CollectionStoragePath)
      ?? panic("Could not borrow receipt collection")
  } 

  execute {
    // Can get receipt IDs
    log(self.receiptCollection.getIds())
    // Can borrow receipt
    log(self.receiptCollection.borrowReceipt(receiptID: 1))
    // Can check if product was bought
    log(self.receiptCollection.hasBoughtProduct(productID: 1))
    // Cannot access receipts directly because contract-level
    log(self.receiptCollection.receipts)
    // Cannot access saveReceipt outside of contract
    log(self.receiptCollection.saveReceipt.getType())
    // Cannot access products dict directly
    log(ChainmonstersProducts.products)
  }
}
