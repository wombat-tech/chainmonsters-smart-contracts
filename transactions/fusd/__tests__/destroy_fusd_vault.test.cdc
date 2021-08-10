import FUSD from "../../../contracts/lib/FUSD.cdc"

// WARNING: This is only for testing. It will detroy an accounts FUSD vault and all its balance!
transaction {
  prepare(signer: AuthAccount) {
    signer.unlink(/public/fusdReceiver)
    signer.unlink(/public/fusdBalance)
    destroy signer.load<@FUSD.Vault>(from: /storage/fusdVault)
  }
}
