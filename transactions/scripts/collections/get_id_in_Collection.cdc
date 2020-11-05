import Chainmonsters from 0xChainmonsters


pub fun main(account: Address, id: UInt64): Bool {
    let collectionRef = getAccount(account).getCapability(/public/RewardCollection)!
        .borrow<&{ChainmonstersReward.RewardCollectionPublic}>()
        ?? panic("Could not get public reward collection reference")

    return collectionRef.borrowNFT(id: id) != nil
}