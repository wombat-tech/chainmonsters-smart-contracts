import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub fun main(): UInt64 {
    return ChainmonstersRewards.totalSupply
}
