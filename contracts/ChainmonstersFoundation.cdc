import ChainmonstersRewards from "./ChainmonstersRewards.cdc"
import PRNG from "./lib/PRNG.cdc"
import NonFungibleToken from "./lib/NonFungibleToken.cdc"

pub contract ChainmonstersFoundation {

  pub event ContractInitialized()
  pub event BundleSold(nftID: UInt64, tier: UInt8)
  pub event UpgradeRolled(nftID: UInt64?, tier: UInt8)
  pub event BundleRedeemed(nftID: UInt64, tier: UInt8, redeemedIDs: [UInt64])

  pub enum Tier: UInt8 {
    pub case RARE
    pub case EPIC
    pub case LEGENDARY
  }

  pub let BundlesCollectionStoragePath: StoragePath
  pub let ReservedTiersCollectionStoragePath: StoragePath
  pub let BonusTiersCollectionStoragePath: StoragePath
  pub let AdminStoragePath: StoragePath

  priv let bundleRewardTierMapping: {UInt32: Tier}

  /**
   * Returns a random bundle NFT of a given tier.
   */
  priv fun pickBundle(tier: Tier): @NonFungibleToken.NFT {
    let tiersCollection =
      self.account.borrow<&TiersCollection>(
        from: self.BundlesCollectionStoragePath
      ) ?? panic("Could not borrow bundles collection")

    let collection = tiersCollection.borrowCollection(tier: tier)!

    let ids = collection.getIDs()

    assert(ids.length > 0, message: "No bundles available for tier ".concat(tier.rawValue.toString()))

    let rng <- PRNG.createFrom(blockHeight: getCurrentBlock().height, uuid: UInt64(ids.length))

    let index = UInt64(rng.range(0, UInt256(ids.length - 1)))

    destroy rng

    return <- collection.withdraw(withdrawID: ids[index])
  }

  /**
   * This function returns an NFT from the reserved collection.
   */
  priv fun pickReservedNFT(rng: &PRNG.Generator, tier: Tier): @NonFungibleToken.NFT {
    let tiersCollection =
      self.account.borrow<&TiersCollection>(
        from: self.ReservedTiersCollectionStoragePath
      ) ?? panic("Could not borrow reserved tiers collection")

    let collection = tiersCollection.borrowCollection(tier: tier)
      ?? panic("Could not borrow collection for tier ".concat(tier.rawValue.toString()))

    let ids = collection.getIDs()

    assert(ids.length > 0, message: "No reserved NFTs available for tier ".concat(tier.rawValue.toString()))

    let index = UInt64(rng.range(0, UInt256(ids.length - 1)))

    return <- collection.withdraw(withdrawID: ids[index])
  }

  /**
   * This function tries to return a random NFT from the bonus collections, starting with the given tier.
   * If no NFTs are left in the given tier it will try to find one in the lower tiers or return nil if all are gone.
   */
  priv fun pickBonusNFT(rng: &PRNG.Generator, tier: Tier): @NonFungibleToken.NFT {
    let tiersCollection =
      self.account.borrow<&TiersCollection>(
        from: self.BonusTiersCollectionStoragePath
      ) ?? panic("Could not borrow bonus tiers collection")

    var currentTier = tier

    while (currentTier.rawValue >= Tier.RARE.rawValue) {
      let collection = tiersCollection.borrowCollection(tier: tier)
        ?? panic("Could not borrow collection for tier ".concat(tier.rawValue.toString()))

      let ids = collection.getIDs()

      if (ids.length == 0) {
        log("No more NFTs available for tier ".concat(currentTier.rawValue.toString()))
        currentTier = Tier(rawValue: currentTier.rawValue - 1)!
        continue
      }

      let index = UInt64(rng.range(0, UInt256(ids.length - 1)))

      return <- collection.withdraw(withdrawID: ids[index])
    }

    panic("No bonus NFTs available")
  }

  /**
   * Rolls for upgrades and returns the resulting NFT
   *
   * RARE rolls: 1.5% chance to upgrade to LEGENDARY, 6% chance to upgrade to EPIC
   * EPIC rolls: 1.5% chance to upgrade to LEGENDARY
   */
  priv fun rollForUpgrade(rng: &PRNG.Generator, tier: Tier): @NonFungibleToken.NFT {
    pre {
      tier != Tier.LEGENDARY: "Can't roll for LEGENDARY upgrade"
    }

    // Roll the dice 1 - 1000
    let roll = rng.range(1, 1000)

    log("Rolled: ".concat(roll.toString()))

    // 1.5% chance to upgrade to LEGENDARY
    let LEGENDARY_UPGRADE_CHANCE: UInt256 = 15
    // 6% chance to upgrade to EPIC
    let EPIC_UPGRADE_CHANCE: UInt256 = 60

    if (roll <= LEGENDARY_UPGRADE_CHANCE) {
      // Every RARE and EPIC roll has a chance of a LEGENDARY upgrade
      let nft <- self.pickBonusNFT(rng: rng, tier: Tier.LEGENDARY)

      emit UpgradeRolled(nftID: nft.id, tier: Tier.LEGENDARY.rawValue)

      return <- nft
    } else if (tier == Tier.RARE && roll <= EPIC_UPGRADE_CHANCE) {
      // RARE rolls have a chance of an EPIC upgrade
      let nft <- self.pickBonusNFT(rng: rng, tier: Tier.EPIC)

      emit UpgradeRolled(nftID: nft.id, tier: Tier.EPIC.rawValue)

      return <- nft
    } else {
      // Otherwise just return the reserved item
      return <- self.pickReservedNFT(rng: rng, tier: tier)
    }
  }

  /**
   * Gets the tier of a bundle with the given rewardID or nil if it's not registered as a bundle.
   */
  pub fun getTierFromBundleRewardID(rewardID: UInt32): Tier? {
    return self.bundleRewardTierMapping[rewardID]
  }

  /**
   * Gets the rewardID of a given tier or nil if it's not registered as a bundle.
   */
  pub fun getBundleRewardIDFromTier(tier: Tier): UInt32? {
    for rewardID in self.bundleRewardTierMapping.keys {
      let currentTier = self.bundleRewardTierMapping[rewardID]!

      if (currentTier == tier) {
        return rewardID
      }
    }

    return nil
  }

  /**
   * The interface to be linked publicly.
   * Any user can check how many NFTs are still available in a given tier.
   */
  pub resource interface TiersCollectionPublic {
    pub fun collectionSize(tier: Tier): Int?
  }

  /**
   * A resource that holds three different ChainmonstersRewards collections, one for each tier
   */
  pub resource TiersCollection: TiersCollectionPublic {
    priv let rareCollection: @ChainmonstersRewards.Collection
    priv let epicCollection: @ChainmonstersRewards.Collection
    priv let legendaryCollection: @ChainmonstersRewards.Collection

    pub fun borrowCollection(tier: Tier): &ChainmonstersRewards.Collection? {
      switch tier {
        case Tier.RARE:
          return &self.rareCollection as &ChainmonstersRewards.Collection
        case Tier.EPIC:
          return &self.epicCollection as &ChainmonstersRewards.Collection
        case Tier.LEGENDARY:
          return &self.legendaryCollection as &ChainmonstersRewards.Collection
        default:
          return nil
      }
    }

    /**
     * Returns the number of NFTs still available in the given tier
     */
    pub fun collectionSize(tier: Tier): Int? {
      switch tier {
        case Tier.RARE:
          return self.rareCollection.getIDs().length
        case Tier.EPIC:
          return self.epicCollection.getIDs().length
        case Tier.LEGENDARY:
          return self.legendaryCollection.getIDs().length
        default:
          return nil
      }
    }

    init() {
      self.rareCollection <- (ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection)
      self.epicCollection <- (ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection)
      self.legendaryCollection <- (ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection)
    }

    destroy() {
      destroy self.rareCollection
      destroy self.epicCollection
      destroy self.legendaryCollection
    }
  }

  pub resource Admin {
    /**
     * Sell a random bundle of a given tier
     */
    pub fun sellBundle(tier: Tier): @NonFungibleToken.NFT {
      let nft <- ChainmonstersFoundation.pickBundle(tier: tier)

      emit BundleSold(nftID: nft.id, tier: tier.rawValue)

      return <- nft
    }

    /**
     * Redeem a bundle for NFTs
     */
    pub fun redeemBundle(nft: @ChainmonstersRewards.NFT): @NonFungibleToken.Collection {
      pre {
        ChainmonstersFoundation.bundleRewardTierMapping[nft.data.rewardID] != nil: "NFT is not a bundle"
      }

      // Create random number generator from the block hash and NFT uuid
      let generator <- PRNG.createFrom(blockHeight: getCurrentBlock().height, uuid: nft.uuid)
      let rng = &generator as &PRNG.Generator

      let tier = ChainmonstersFoundation.bundleRewardTierMapping[nft.data.rewardID]!

      let tokens <- (ChainmonstersRewards.createEmptyCollection() as! @ChainmonstersRewards.Collection)

      switch (tier) {
        // RARE rolls twice for RARE items
        case Tier.RARE:
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))

        // EPIC rolls once for an EPIC item and twice for RARE items
        case Tier.EPIC:
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.EPIC))
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))

        // LEGENDARY receives a guaranteed LEGENDARY item and two RARE items
        case Tier.LEGENDARY:
          tokens.deposit(token: <- ChainmonstersFoundation.pickReservedNFT(rng: rng, tier: Tier.LEGENDARY))
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))
          tokens.deposit(token: <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: Tier.RARE))
      }

      // Check that tokens collection has the correct length
      if (tier == Tier.RARE) {
        assert(tokens.getIDs().length == 2, message: "Did not return 2 tokens for RARE redeem")
      } else {
        assert(tokens.getIDs().length == 3, message: "Did not return 3 tokens for EPIC/LEGENDARY redeem")
      }

      emit BundleRedeemed(nftID: nft.id, tier: tier.rawValue, redeemedIDs: tokens.getIDs());

      // Burn the NFT
      destroy nft

      // Destroy the rng resource
      destroy generator

      // Return the tokens
      return <- tokens
    }

    /**
     * Manually raffle for an NFT based on a tier with the chance of an upgrade.
     * Can be used for testing or giveaways
     */
    pub fun manualRaffle(rng: &PRNG.Generator, tier: Tier): @NonFungibleToken.NFT? {
      return <- ChainmonstersFoundation.rollForUpgrade(rng: rng, tier: tier)
    }

    pub fun createNewAdmin(): @Admin {
      return <- create Admin()
    }

    pub fun createNewTiersCollection(): @TiersCollection {
      return <- create TiersCollection()
    }
  }

  init(
    rareBundleRewardID: UInt32,
    epicBundleRewardID: UInt32,
    legendaryBundleRewardID: UInt32
  ) {

    self.BundlesCollectionStoragePath = /storage/cmfBundlesCollection
    self.ReservedTiersCollectionStoragePath =  /storage/cmfReservedTiersCollection
    self.BonusTiersCollectionStoragePath = /storage/cmfBonusTiersCollection
    self.AdminStoragePath = /storage/cmfAdmin

    self.bundleRewardTierMapping = {
      rareBundleRewardID: Tier.RARE,
      epicBundleRewardID: Tier.EPIC,
      legendaryBundleRewardID: Tier.LEGENDARY
    }

    let admin <- create Admin()

    // Bundles
    self.account.save<@TiersCollection>(
      <- admin.createNewTiersCollection(),
      to: self.BundlesCollectionStoragePath
    )

    // Public interface for bundle collections
    self.account.link<&{TiersCollectionPublic}>(
      /public/cmfBundlesCollection,
      target: self.BundlesCollectionStoragePath
    )

    // Reserved Items
    self.account.save<@TiersCollection>(
      <- admin.createNewTiersCollection(),
      to: self.ReservedTiersCollectionStoragePath
    )

    // Bonus Items
    self.account.save<@TiersCollection>(
      <- admin.createNewTiersCollection(),
      to: self.BonusTiersCollectionStoragePath
    )

    self.account.save<@Admin>(<- admin, to: self.AdminStoragePath)

    emit ContractInitialized()
  }
}
