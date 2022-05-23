import ChainmonstersProducts from "../../contracts/ChainmonstersProducts.cdc"

pub struct Product {
  pub let price: UFix64
  pub let supply: UInt32?
  pub let sales: UInt32

  init(price: UFix64, supply: UInt32?, sales: UInt32) {
    self.price = price
    self.supply = supply
    self.sales = sales
  }
}

pub fun main(productIDs: [UInt32]): {UInt32: Product?} {
  let results: {UInt32: Product?} = {}

  for productID in productIDs {
    let product = ChainmonstersProducts.getProduct(productID: productID)
    
    if (product != nil) {
      results[productID] = Product(
        price: product!.price,
        supply: product!.totalSupply,
        sales: product!.getSales()
      )
    }
  }

  return results
}
