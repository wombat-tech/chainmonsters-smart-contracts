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
    let name = ChainmonstersRewards.getRewardMetaData(rewardID: rewardID)
    let url = ChainmonstersRewards.getRewardImageURL(rewardID: rewardID)

    if name != nil && url != nil {
        return PurchaseData(id: UInt64(rewardID), name: name, amount: 1.0, description: "A Chainmonsters Reward", imageURL: url)
    }
    
    panic("Reward not found")
}