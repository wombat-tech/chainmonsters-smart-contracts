import ChainmonstersNFT from 0xCHAINMONSTERS

// This script returns the full metadata associated with a Reward
// in the Chainmonsters smart contract


pub fun main(rewardID: UInt32): {String:String} {
    let metadata = ChainmonstersNFT.getRewardMetaData(rewardID: rewardID) ?? panic("Reward doesn't exist")
    log(metadata)
    return metadata
}



