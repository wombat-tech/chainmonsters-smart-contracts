import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub fun main(account: Address): [UInt64] {

    let acct = getAccount(account)

    let collectionRef = acct.getCapability(/public/ChainmonstersRewardCollection)
                            .borrow<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>()!

    return collectionRef.getIDs()
}
