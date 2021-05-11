import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"


pub fun main(account: Address, id: UInt64): String {

    // get the public capability for the owner's reward collection
    // and borrow a reference to it
    let collectionRef = getAccount(account).getCapability(/public/ChainmonstersRewardCollection)!
        .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()
        ?? panic("Could not get public reward collection reference")

    // Borrow a reference to the specified reward
    let token = collectionRef.borrowReward(id: id)
        ?? panic("Could not borrow a reference to the specified reward")

    // Get the NFT's metadata to access its Reward IDs
    let data = token.data

    // Use the NFT's reward ID 
    // to get all the metadata associated with that reward
    let metadata = ChainmonstersRewards.getRewardMetaData(rewardID: data.rewardID) ?? panic("Reward doesn't exist")

    return metadata
}
