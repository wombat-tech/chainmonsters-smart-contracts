import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"

pub struct RewardSupply {
  pub var totalSupply: UInt32
  pub var maxSupply: UInt32

  init(totalSupply: UInt32, maxSupply: UInt32) {
    self.totalSupply = totalSupply
    self.maxSupply = maxSupply
  }
}

pub fun main(rewardID: UInt32): RewardSupply? {
  let totalSupply = ChainmonstersRewards.numberMintedPerReward[rewardID]
  let maxSupply = ChainmonstersRewards.getRewardMaxSupply(rewardID: rewardID)

  if (totalSupply == nil || maxSupply == nil) {
    return nil
  }

  return RewardSupply(totalSupply: totalSupply!, maxSupply: maxSupply!)
}
