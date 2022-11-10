import DapperUtilityCoin from "../../contracts/lib/DapperUtilityCoin.cdc"
import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * This transaction allows to purchase an NFT with the given rewardID for a specific price.
 */
transaction(merchantAddress: Address, rawTier: UInt8, price: UFix64) {
    let balanceBeforeTransfer: UFix64
    let mainDUCVault: &DapperUtilityCoin.Vault
    let paymentVault: @FungibleToken.Vault
    let sellerPaymentReceiver: &{FungibleToken.Receiver}

    let foundationAdminRef: &ChainmonstersFoundation.Admin
    let buyerRewardsCollection: &ChainmonstersRewards.Collection
    var purchasedTokenId: UInt64?

    prepare(cmAdmin: AuthAccount, dapper: AuthAccount, buyer: AuthAccount) {
        // Borrow reference to the DapperUtilityCoin vault
        self.mainDUCVault = dapper
            .borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Could not borrow reference to DapperUtilityCoin vault")

        // Initial balance for post-transaction leakage check
        self.balanceBeforeTransfer = self.mainDUCVault.balance

        // Withdraw the payment amount from the DapperUtilityCoin vault
        self.paymentVault <- self.mainDUCVault.withdraw(amount: price)

        // Borrow reference to the payment receiver
        self.sellerPaymentReceiver = getAccount(merchantAddress)
            .getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            .borrow()
            ?? panic("Could not borrow reference to DapperUtilityCoin receiver")

        // Borrow reference to the ChainmonstersRewards admin resource
        self.foundationAdminRef = cmAdmin
            .borrow<&ChainmonstersFoundation.Admin>(from: ChainmonstersFoundation.AdminStoragePath)
            ?? panic("Could not borrow reference to ChainmonstersFoundation admin")

        // Check for ChainmonstersRewards collection and create one if needed
        if buyer.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection) == nil {
            // Create a new ChainmonstersRewards collection
            let collection <- ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection
            // Put the new Collection in storage
            buyer.save(<-collection, to: /storage/ChainmonstersRewardCollection)
            // Create a public capability for the collection
            buyer.link<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection, target: /storage/ChainmonstersRewardCollection)
        }

        // Borrow reference to the ChainmonstersRewards collection
        self.buyerRewardsCollection = buyer.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)!

        // Initialize empty purchasedTokenId for post-transaction sanity check
        self.purchasedTokenId = nil
    }

    execute {
        let tier = ChainmonstersFoundation.Tier(rawValue: rawTier) ?? panic("Invalid tier")

        // Transfer DUC to seller
        self.sellerPaymentReceiver.deposit(from: <- self.paymentVault)

        // Purchase NFT
        let token <- self.foundationAdminRef.sellBundle(tier: tier)

        // Update purchasedTokenId with newly minted NFT id
        self.purchasedTokenId = token.id

        // Transfer NFT to buyer
        self.buyerRewardsCollection.deposit(token: <- token)
    }

    post {
        self.mainDUCVault.balance == self.balanceBeforeTransfer: "DUC leakage"
        self.buyerRewardsCollection.borrowReward(id: self.purchasedTokenId!) != nil: "NFT not deposited"
    }
}
