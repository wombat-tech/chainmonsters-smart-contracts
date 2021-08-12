import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"

pub fun main(address: Address, productID: UInt32): Bool {
  let collection = getAccount(address).getCapability<&ChainmonstersProducts.ReceiptCollection>(ChainmonstersProducts.CollectionPublicPath).borrow()
    ?? panic("Could not borrow receipt collection")
  return collection.hasBoughtProduct(productID: productID)
}
