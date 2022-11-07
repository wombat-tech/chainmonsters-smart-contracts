import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

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

pub fun main(merchantAddress: Address, rewardID: UInt32, price: UFix64): PurchaseData {
    let externalRewardMetadata = ChainmonstersRewards.getExternalRewardMetadata(rewardID: rewardID)

    if (externalRewardMetadata == nil) {
        panic("Reward not found")
    }

    let name = externalRewardMetadata!["name"]
    let description = externalRewardMetadata!["description"]
    let imageURL = "https://chainmonsters.com/images/rewards/".concat(rewardID.toString()).concat(".png")

    if (name != nil && description != nil) {
        return PurchaseData(id: UInt64(rewardID), name: name, amount: 1.0, description: description, imageURL: imageURL)
    }
    
    panic("Reward not found")
}