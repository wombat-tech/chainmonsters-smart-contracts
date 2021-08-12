import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"

pub struct Data {
  pub let price: UFix64
  pub let paymentVaultType: Type
  pub let sales: UInt32
  pub let saleEndTime: UFix64?
  pub let metadata: String?

  init(price: UFix64, paymentVaultType: Type, sales: UInt32, saleEndTime: UFix64?, metadata: String?) {
    self.price = price
    self.paymentVaultType = paymentVaultType
    self.sales = sales
    self.saleEndTime = saleEndTime
    self.metadata = metadata
  }
}

pub fun main(productID: UInt32): Data? {
  if let product = ChainmonstersProducts.getProduct(productID: productID) {
    return Data(
      price: product.price,
      paymentVaultType: product.paymentVaultType,
      sales: product.getSales(),
      saleEndTime: product.saleEndTime,
      metadata: product.metadata
    )
  }

  return nil
}
