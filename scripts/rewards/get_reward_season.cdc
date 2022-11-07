import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub fun main(rewardID: UInt32): UInt32? {
    return ChainmonstersRewards.getRewardSeason(rewardID: rewardID)
}
