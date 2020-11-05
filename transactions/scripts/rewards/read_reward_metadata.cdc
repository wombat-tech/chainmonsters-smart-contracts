import ChainmonstersRewards from 0xCHAINMONSTERS

pub fun main(rewardID: UInt32): String {
    return ChainmonstersRewards.getRewardMetaData(rewardID: rewardID) ?? panic("Reward does not exist")
    log(metdata)
    return metadata
}