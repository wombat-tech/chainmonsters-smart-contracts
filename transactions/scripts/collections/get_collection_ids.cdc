import ChainmonstersRewards from 0xCHAINMONSTERS

pub fun main(account: Address): [UInt64] {

    let acct = getAccount(account)

    let collectionRef = acct.getCapability(/public/RewardCollection)!
                            .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()!

    log(collectionRef.getIDs())

    return collectionRef.getIDs()
}