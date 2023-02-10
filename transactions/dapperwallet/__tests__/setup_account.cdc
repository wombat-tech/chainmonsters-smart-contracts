import DapperUtilityCoin from "../../../contracts/lib/DapperUtilityCoin.cdc";
import FungibleToken from "../../../contracts/lib/FungibleToken.cdc";
import TokenForwarding from "../../../contracts/lib/TokenForwarding.cdc";

// This sets up a DUC vault for an account. 
// This is the wrong way to do it, but we just need it for testing :^)
transaction(admin: Address) {
    prepare(signer: AuthAccount) {
        if signer.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinReceiver) == nil {
            let adminAcct = getAccount(admin)
            let ducReceiver = adminAcct.getCapability(/public/dapperUtilityCoinReceiver)
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: ducReceiver)

            // save it to the account
            signer.save(<- ducForwarder, to: /storage/dapperUtilityCoinReceiver)

            // create a public capability for the collection
            signer.link<&DapperUtilityCoin.Vault{FungibleToken.Receiver}>(
                /public/dapperUtilityCoinReceiver,
                target: /storage/dapperUtilityCoinReceiver
            )
        }
    }
}
