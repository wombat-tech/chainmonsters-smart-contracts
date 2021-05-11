import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub fun main(): UInt32 {
    return ChainmonstersRewards.nextRewardID
}
