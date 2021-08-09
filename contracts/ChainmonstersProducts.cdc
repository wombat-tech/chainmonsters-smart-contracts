import FUSD from "./lib/FUSD.cdc"
import FungibleToken from "./lib/FungibleToken.cdc"

pub contract ChainmonstersProducts {

  /**
   * Contract events
   */
  pub event ContractInitialized()
  pub event ProductCreated(product: Product)
  pub event ProductSaleChanged(productID: UInt32, saleEnabled: Bool)
  pub event ProductPurchased(product: Product, buyer: Address?)

  /**
   * Contract-level fields
   */
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath

  access(self) var products: {UInt32: Product}
  access(self) var salesPerProduct: {UInt32: UInt32}
  pub var nextProductID: UInt32
  pub var paymentReceiverCapability: Capability<&FUSD.Vault{FungibleToken.Receiver}>

  /**
   * Structs
   */
  pub struct Product {
    pub let productID: UInt32

    pub let price: UFix64
    pub var saleEnabled: Bool
    pub let totalSupply: UInt32?
    pub let saleEndTime: UFix64?

    pub fun setSaleEnabled(saleEnabled: Bool) {
      self.saleEnabled = saleEnabled
    }

    init(price: UFix64, saleEnabled: Bool, totalSupply: UInt32?, saleEndTime: UFix64?) {
      let productID = ChainmonstersProducts.nextProductID

      self.productID = productID
      self.price = price
      self.saleEnabled = saleEnabled
      self.totalSupply = totalSupply
      self.saleEndTime = saleEndTime

      // Initialize product sale count to 0
      ChainmonstersProducts.salesPerProduct[productID] = 0

      // Increment global productID counter
      ChainmonstersProducts.nextProductID = productID + 1

      emit ProductCreated(product: self)
    }
  }
  
  /**
   * Resources
   */
  pub resource ReceiptCollection {
    pub var receipts: @[Receipt]

    pub fun saveReceipt(receipt: @Receipt) {
      self.receipts.append(<- receipt)
    }

    init () {
      self.receipts <- []
    }

    destroy() {
      destroy self.receipts
    }
  }

  pub resource Receipt {
    pub var product: Product

    init(product: Product) {
      self.product = product
    }
  }

  pub resource Admin {
    pub fun createNewProduct(price: UFix64, saleEnabled: Bool, totalSupply: UInt32?, saleEndTime: UFix64?) {
      var product = Product(
        price: price, 
        saleEnabled: saleEnabled, 
        totalSupply: totalSupply, 
        saleEndTime: saleEndTime
      )
      
      ChainmonstersProducts.products[product.productID] = product
    }

    pub fun setProductSaleEnabled(productID: UInt32, saleEnabled: Bool) {
      var product = ChainmonstersProducts.products[productID] ?? panic("Product not found")

      product.setSaleEnabled(saleEnabled: saleEnabled)

      ChainmonstersProducts.products[productID] = product

      emit ProductSaleChanged(productID: productID, saleEnabled: saleEnabled)
    }

    // createNewAdmin creates a new Admin resource
    pub fun createNewAdmin(): @Admin {
        return <-create Admin()
    }
  }

  pub fun getProduct(productID: UInt32): Product? {
    return self.products[productID]
  }

  // Contract Level Functions
  pub fun purchase(
    productID: UInt32,
    buyerReceiptCollection: &ReceiptCollection,
    buyerPayment: @FungibleToken.Vault
  ) {
    pre {
      self.products[productID] != nil: 
        "Product not found"
      self.products[productID]!.saleEnabled: 
        "Product sale is not enabled"
      self.products[productID]!.totalSupply != nil && self.salesPerProduct[productID] != nil && self.salesPerProduct[productID]! <= self.products[productID]!.totalSupply!: 
        "Product out of stock"
      self.products[productID]!.saleEndTime == nil || getCurrentBlock().timestamp < self.products[productID]!.saleEndTime!: 
        "Product sale has ended"
      buyerPayment.balance == self.products[productID]!.price:
        "Payment does not equal product price"
      self.paymentReceiverCapability.borrow() != nil:
        "Could not borrow payment receiver"
    }

    let product = ChainmonstersProducts.products[productID]!

    // Transfer the payment from buyer to payment receiver
    self.paymentReceiverCapability.borrow()!.deposit(from: <- buyerPayment)

    // Save receipt to the buyer's collection
    buyerReceiptCollection.saveReceipt(receipt: <- create Receipt(product: product))

    // Increment sales counter for this product
    self.salesPerProduct[productID] = self.salesPerProduct[productID]! + 1

    emit ProductPurchased(product: product, buyer: buyerReceiptCollection.owner?.address)
  }

  init() {
    self.CollectionStoragePath = /storage/chainmonstersProductsCollection
    self.CollectionPublicPath = /public/chainmonstersProductsCollection

    self.products = {}
    self.salesPerProduct = {}
    self.nextProductID = 1
    
    self.paymentReceiverCapability = self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

    self.account.save<@Admin>(<- create Admin(), to: /storage/chainmonstersProductsAdmin)

    emit ContractInitialized()
  }
}
