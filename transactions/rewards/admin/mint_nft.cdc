import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import FlowStorageFees from "../../../contracts/lib/FlowStorageFees.cdc"
import FlowToken from "../../../contracts/lib/FlowToken.cdc"
import FungibleToken from "../../../contracts/lib/FungibleToken.cdc"

// This transaction is what an admin would use to mint a single new NFT
// and deposit it in a user's collection

// Parameters
//
// rewardID: the ID of a reward from which a new NFT is minted
// recipientAddr: the Flow address of the account receiving the newly minted NFT


transaction(rewardID: UInt32, recipientAddr: Address) {
    // local variable for the admin reference
    let adminRef: &ChainmonstersRewards.Admin
    let payerVaultRef: &FlowToken.Vault

    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)!

        // borrow reference to the signer vault
        self.payerVaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
    }

    execute {
        // Borrow a reference to the specified reward
        //let rewardRef = self.adminRef.borrowReward(rewardID: rewardID)

        // Mint a new NFT
        let nft1 <- self.adminRef.mintReward(rewardID: rewardID)

        // get the public account object for the recipient
        let recipient = getAccount(recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/ChainmonstersRewardCollection)
                                   .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()!

        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-nft1)

         // This function checks if the receivers storage is over capacity and transfers FLOW token as needed
        fun checkStorageAndTopUp(payerVaultRef: &FlowToken.Vault, receiver: PublicAccount): Bool {

            log("Storage left")
            let storageLeft = Int64(receiver.storageCapacity) - Int64(receiver.storageUsed)
            log(storageLeft)

            if (storageLeft < 0) {

                log("Not enough Storage! Difference")
                let requiredStorageInMB = UFix64(-storageLeft) * 0.000001
                log(requiredStorageInMB)
                
                log("FLOW topup required for storage")
                let topupDeposit = FlowStorageFees.storageCapacityToFlow(requiredStorageInMB)
                log(topupDeposit)

                let flowReceiver = receiver.getCapability(/public/flowTokenReceiver)
                                            .borrow<&{FungibleToken.Receiver}>()!

                flowReceiver.deposit(from: <- payerVaultRef.withdraw(amount: topupDeposit))
                log("Transferred FLOW tokens")

                return true
            }

            return false
        }

        checkStorageAndTopUp(payerVaultRef: self.payerVaultRef, receiver: recipient);
    }
}
