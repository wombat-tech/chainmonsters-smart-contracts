import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"



pub fun main(account: Address, id: UInt64): UInt32 {
    let collectionRef = getAccount(account).getCapability(/public/ChainmonstersRewardCollection)!
        .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()
        ?? panic("Could not get public reward collection reference")

    let token = collectionRef.borrowReward(id: id)
        ?? panic("Could not borrow a reference to the specified nft")

    let data = token.data

    return data.rewardID
}
