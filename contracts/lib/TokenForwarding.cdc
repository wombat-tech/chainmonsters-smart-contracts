
import FungibleToken from "./FungibleToken.cdc"

pub contract TokenForwarding {

    // Event that is emitted when tokens are deposited to the target receiver
    pub event ForwardedDeposit(amount: UFix64, from: Address?)

    pub resource Forwarder: FungibleToken.Receiver {

        // This is where the deposited tokens will be sent.
        // The type indicates that it is a reference to a receiver
        //
        access(self) var recipient: Capability

        // deposit
        //
        // Function that takes a Vault object as an argument and forwards
        // it to the recipient's Vault using the stored reference
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            let receiverRef = self.recipient.borrow<&{FungibleToken.Receiver}>()!

            let balance = from.balance

            receiverRef.deposit(from: <-from)

            emit ForwardedDeposit(amount: balance, from: self.owner?.address)
        }

        // changeRecipient changes the recipient of the forwarder to the provided recipient
        //
        pub fun changeRecipient(_ newRecipient: Capability) {
            pre {
                newRecipient.borrow<&{FungibleToken.Receiver}>() != nil: "Could not borrow Receiver reference from the Capability"
            }
            self.recipient = newRecipient
        }

        init(recipient: Capability) {
            pre {
                recipient.borrow<&{FungibleToken.Receiver}>() != nil: "Could not borrow Receiver reference from the Capability"
            }
            self.recipient = recipient
        }
    }

    // createNewForwarder creates a new Forwarder reference with the provided recipient
    //
    pub fun createNewForwarder(recipient: Capability): @Forwarder {
        return <-create Forwarder(recipient: recipient)
    }
}

