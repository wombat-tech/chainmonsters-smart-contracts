import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub fun main(): [ChainmonstersRewards.Reward] {
    return ChainmonstersRewards.getAllRewards()
}
