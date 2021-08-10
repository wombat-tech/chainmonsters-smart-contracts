import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"
import FUSD from "../../../contracts/lib/FUSD.cdc"
import FungibleToken from "../../../contracts/lib/FungibleToken.cdc"

// Create a product
transaction(
  primaryReceiver: Address, 
  secondaryReceiver: Address, 
  saleEnabled: Bool, 
  totalSupply: UInt32?, 
  saleEndTime: UFix64?, 
  metadata: String?
) {
  let admin: &ChainmonstersProducts.Admin
  let primaryReceiverCapability: Capability<&FUSD.Vault{FungibleToken.Receiver}>
  let secondaryReceiverCapability: Capability<&FUSD.Vault{FungibleToken.Receiver}>
  
  prepare(acct: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    self.admin = acct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
    self.primaryReceiverCapability = getAccount(primaryReceiver).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
    self.secondaryReceiverCapability = getAccount(secondaryReceiver).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
  } 

  execute {
    let paymentVaultType = Type<@FUSD.Vault>()
    let priceCuts = [
      // Primary and fallback cut
      ChainmonstersProducts.PriceCut(
        receiver: self.primaryReceiverCapability,
        amount: 100.0
      ),
      // Secondary cut
      ChainmonstersProducts.PriceCut(
        receiver: self.secondaryReceiverCapability,
        amount: 10.0
      )
    ]

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
