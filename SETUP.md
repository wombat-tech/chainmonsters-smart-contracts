# Contract setup

1. Start the emulator
   ```
   flow project start-emulator
   ```
1. Deploy all contracts
   ```
   flow project deploy
   ```
1. Create seller account
   ```
   flow accounts create --key 376501ec6fc4ada8c53ad959ae81e49a0d82c845c91a3669814c032dbb41d567e24317355557668208e75109fd9b027b41137bff90856516fda3efe40e798fed
   ```
   1. Setup Rewards for seller
      ```
      flow transactions send ./transactions/rewards/setup_account.cdc --signer seller-account
      ```
   1. Setup FUSD for seller
      ```
      flow transactions send ./transactions/fusd/setup_account.cdc --signer seller-account
      ```
   1. Setup Marketplace for seller
      ```
      flow transactions send ./transactions/marketplace/setup_account.cdc --signer seller-account
      ```
1. Create buyer account

   ```
   flow accounts create --key 7c181e2f6d5f610c500fee438b7b817c81cea296292e2c88debdd549011ede73e1478c87dd9bfcfbb60d2699d7df6a6d75120b7b4ca09343e6c279f2ce8ee9d5
   ```

   1. Setup Rewards for buyer
      ```
      flow transactions send ./transactions/rewards/setup_account.cdc --signer buyer-account
      ```
   1. Setup FUSD for buyer
      ```
      flow transactions send ./transactions/fusd/setup_account.cdc --signer buyer-account
      ```
   1. Setup Marketplace for buyer

      ```
      flow transactions send ./transactions/marketplace/setup_account.cdc --signer buyer-account
      ```

## Mint & Distribute tokens

1. Create a reward

   ```
   flow transactions send ./transactions/rewards/admin/create_reward.cdc --arg String:foobar --arg UInt32:1337
   ```

1. Mint an NFT for seller

   ```
   flow transactions send ./transactions/rewards/admin/mint_nft.cdc --arg UInt32:1 --arg Address:01cf0e2f2f715450
   ```

## FUSD

1. Mint some FUSD for the buyer & seller

   ```
   flow transactions send ./transactions/fusd/mint_tokens.cdc --arg Address:179b6b1cb6755e31 --arg UFix64:9001.0

   flow transactions send ./transactions/fusd/mint_tokens.cdc --arg Address:01cf0e2f2f715450 --arg UFix64:9001.0
   ```

Everything up until here has been done already and is saved in the persisted emulator chain

# Check status

1. Check the created rewards

   ```
   flow scripts execute ./scripts/rewards/get_all_rewards.cdc
   ```

   > Should be `A.f8d6e0586b0a20c7.ChainmonstersRewards.Reward(rewardID: 1, season: 0, metadata: "foobar")

1. Check the NFTs in the seller collection

   ```
   flow scripts execute ./scripts/rewards/get_collection_ids.cdc --arg Address:01cf0e2f2f715450
   ```

   > Should be `1`

1. Check FUSD balances

   ```
   flow scripts execute ./scripts/fusd/get_balance.cdc --arg Address:01cf0e2f2f715450

   flow scripts execute ./scripts/fusd/get_balance.cdc --arg Address:179b6b1cb6755e31
   ```

   > Should be `9001.0`

# Market Interactions

## Seller

Address: `01cf0e2f2f715450`

1. Sell the NFT

   ```
   flow transactions send ./transactions/marketplace/sell_market_item.cdc --arg UInt64:1 --arg UFix64:1337.0 --signer seller-account
   ```

1. Check items for sale

   ```
   flow scripts execute ./scripts/marketplace/get_collection_ids.cdc --arg Address:01cf0e2f2f715450
   ```

   > Should be `1`

### Buyer

Address: `179b6b1cb6755e31`

1. Buy item
   ```
   flow transactions send ./transactions/marketplace/buy_market_item.cdc --arg UInt64:1 --arg Address:01cf0e2f2f715450 --signer buyer-account
   ```
1. Check sellers sales
   ```
   flow scripts execute ./scripts/marketplace/get_collection_ids.cdc --arg Address:01cf0e2f2f715450
   ```
   > Should be empty
1. Check buyers rewards collection
   ```
   flow scripts execute ./scripts/rewards/get_collection_ids.cdc --arg Address:179b6b1cb6755e31
   ```
   > Should be `1`
1. Check seller FUSD balance
   ```
   flow scripts execute ./scripts/fusd/get_balance.cdc --arg Address:01cf0e2f2f715450
   ```
   > Should be `10338.0`

Done 🎉

# Testnet Setup

The contracts have been done on testnet at `0x75783e3c937304a8`.

You have to execute all setup transactions yourself for your testaccounts.
