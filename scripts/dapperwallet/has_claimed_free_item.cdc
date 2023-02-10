import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersFoundation from "../../contracts/ChainmonstersFoundation.cdc"

/**
 * Check if a user has claimed the free item already
 */
pub fun main(adminAddress: Address, userAddress: Address): Bool {
  let admin = getAuthAccount(adminAddress)
  let emptyTracker: [Address] = []
  let tracker = admin.borrow<&[Address]>(from: /storage/freeClaimTracker)

  if (tracker == nil) {
    return true
  }

  return tracker!.contains(userAddress)
}
