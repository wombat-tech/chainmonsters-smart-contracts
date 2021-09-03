import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"

pub fun main(productID: UInt32): UInt32 {
  let product = ChainmonstersProducts.getProduct(productID: productID)

  if product == nil || product!.totalSupply == nil {
    return 0
  }

  return product!.totalSupply! - product!.getSales()
}
