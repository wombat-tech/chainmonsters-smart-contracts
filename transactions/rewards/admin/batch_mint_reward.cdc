import ChainmonstersRewards from "../../../contracts/ChainmonstersRewards.cdc"
import FlowStorageFees from "../../../contracts/lib/FlowStorageFees.cdc"
import FlowToken from "../../../contracts/lib/FlowToken.cdc"
import FungibleToken from "../../../contracts/lib/FungibleToken.cdc"

// This transaction mints multiple nfts from a single reward 

transaction(rewardID: UInt32, quantity: UInt64, recipientAddr: Address) {

    // Local variable for the topshot Admin object
    let adminRef: &ChainmonstersRewards.Admin
    let payerVaultRef: &FlowToken.Vault

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&ChainmonstersRewards.Admin>(from: /storage/ChainmonstersAdmin)!

        // borrow reference to the signer vault
        self.payerVaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
    }

    execute {
        // Mint all the new NFTs
        let collection <- self.adminRef.batchMintReward(rewardID: rewardID, quantity: quantity)

        // Get the account object for the recipient of the minted tokens
        let recipient = getAccount(recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/ChainmonstersRewardCollection)
                                   .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()!

        // deposit the NFT in the receivers collection
        receiverRef.batchDeposit(tokens: <-collection)

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
