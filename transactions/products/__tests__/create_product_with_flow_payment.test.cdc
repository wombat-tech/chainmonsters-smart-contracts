import ChainmonstersProducts from "../../../contracts/ChainmonstersProducts.cdc"
import FlowToken from "../../../contracts/lib/FlowToken.cdc"
import FungibleToken from "../../../contracts/lib/FungibleToken.cdc"

// Create a product with FLOW token price
transaction(primaryReceiver: Address, secondaryReceiver: Address) {
  let admin: &ChainmonstersProducts.Admin
  let primaryReceiverCapability: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
  let secondaryReceiverCapability: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
  
  prepare(acct: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    self.admin = acct.borrow<&ChainmonstersProducts.Admin>(from: /storage/chainmonstersProductsAdmin)
      ?? panic("Could not borrow a reference to the Admin resource")
    self.primaryReceiverCapability = getAccount(primaryReceiver).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    self.secondaryReceiverCapability = getAccount(secondaryReceiver).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
  } 

  execute {
    let paymentVaultType = Type<@FlowToken.Vault>()
    let priceCuts = [
      // Primary and fallback cut
      ChainmonstersProducts.PriceCut(
        receiver: self.primaryReceiverCapability,
        amount: 9000.0
      ),
      // Secondary cut
      ChainmonstersProducts.PriceCut(
        receiver: self.secondaryReceiverCapability,
        amount: 1.0
      )
    ]

    self.admin.createNewProduct(
      priceCuts: priceCuts,
      paymentVaultType: paymentVaultType,
      saleEnabled: true,
      totalSupply: nil,
      saleEndTime: nil,
      metadata: nil
    )
  }
}
