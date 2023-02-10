import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

pub struct PurchaseData {
    pub let id: UInt64
    pub let name: String?
    pub let amount: UFix64
    pub let description: String?
    pub let imageURL: String?

    init(id: UInt64, name: String?, amount: UFix64, description: String?, imageURL: String?) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
    }
}

/**
 * Return the purchase metadata for a bundle purchase
 */
pub fun main(merchantAddress: Address, rawTier: UInt8, price: UFix64): PurchaseData {
    pre {
        ChainmonstersFoundation.Tier(rawValue: rawTier) != nil: "Invalid tier"
    }

    let tier = ChainmonstersFoundation.Tier(rawValue: rawTier)!
    let rewardID = ChainmonstersFoundation.getBundleRewardIDFromTier(tier: tier) ?? panic("No bundle registered with this tier")

    let externalRewardMetadata = ChainmonstersRewards.getExternalRewardMetadata(rewardID: rewardID)

    if (externalRewardMetadata == nil) {
        panic("Reward not found")
    }

    let name = externalRewardMetadata!["name"]
    let description = externalRewardMetadata!["description"]
    let imageURL = "https://chainmonsters.com/images/rewards/".concat(rewardID.toString()).concat(".png")

    if (name != nil && description != nil) {
        return PurchaseData(id: UInt64(rewardID), name: name, amount: price, description: description, imageURL: imageURL)
    }
    
    panic("Reward not found")
}
