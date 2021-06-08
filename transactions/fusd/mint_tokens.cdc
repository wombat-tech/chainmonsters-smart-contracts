import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"

transaction(recipient: Address, amount: UFix64) {
    let tokenAdmin: &FUSD.Administrator
    let tokenReceiver: &FUSD.Vault{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        self.tokenAdmin = signer
        .borrow<&FUSD.Administrator>(from: FUSD.AdminStoragePath)
        ?? panic("Signer is not the token admin")

        self.tokenReceiver = getAccount(recipient)
        .getCapability(/public/fusdReceiver)
        .borrow<&FUSD.Vault{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")
    }

    execute {
        let minter <- self.tokenAdmin.createNewMinter()
        let mintedVault <- minter.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
