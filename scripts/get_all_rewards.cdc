import ChainmonstersNFT from 0x179b6b1cb6755e31

// This script returns an array of all the reward
// that have ever been created for Chainmonsters

pub fun main(): [ChainmonstersNFT.Reward] {
    log(ChainmonstersNFT.getAllRewards())
    return ChainmonstersNFT.getAllRewards()
}