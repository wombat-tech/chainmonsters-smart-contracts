import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import PRNG from "../../contracts/lib/PRNG.cdc"

/**
 * Manually raffle for an NFT based on a tier with the chance of an upgrade. 
 * Salt should be a random number.
 */
transaction(rawTier: UInt8, salt: UInt64) {
  let foundationAdminRef: &ChainmonstersFoundation.Admin
  let userCollectionRef: &ChainmonstersRewards.Collection

  prepare(cmAdmin: AuthAccount, user: AuthAccount) {
    // borrow a reference to the user's collection
    self.userCollectionRef = user.borrow<&ChainmonstersRewards.Collection>(from: /storage/ChainmonstersRewardCollection)
      ?? panic("Could not borrow a reference to the user's stored Rewards collection")

    // Borrow reference to the ChainmonstersFoundation admin resource
    self.foundationAdminRef = cmAdmin
      .borrow<&ChainmonstersFoundation.Admin>(from: ChainmonstersFoundation.AdminStoragePath)
      ?? panic("Could not borrow reference to ChainmonstersFoundation admin")
  }

  pre {
    ChainmonstersFoundation.Tier(rawValue: rawTier) != nil: "Tier is not valid"
  }

  execute {
    let tier = ChainmonstersFoundation.Tier(rawValue: rawTier)!

    let generator <- PRNG.createFrom(blockHeight: getCurrentBlock().height, uuid: salt)
    let rng = &generator as &PRNG.Generator

    // Raffle item
    let token <- self.foundationAdminRef.manualRaffle(rng: rng, tier: tier) ?? panic("Did not receive a token")

    // Deposit the raffled NFTs into the user's collection
    self.userCollectionRef.deposit(token: <- token)

    destroy generator
  }
}
