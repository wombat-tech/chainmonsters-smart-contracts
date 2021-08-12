import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"

pub fun main(productID: UInt32): ChainmonstersProducts.Product? {
  return ChainmonstersProducts.getProduct(productID: productID)
}
