# Contract setup

1. Start the emulator `flow project start-emulator`
1. Deploy all contracts `flow project deploy`
1. Create seller account `flow accounts create --key 376501ec6fc4ada8c53ad959ae81e49a0d82c845c91a3669814c032dbb41d567e24317355557668208e75109fd9b027b41137bff90856516fda3efe40e798fed`
   1. Setup Rewards for seller `flow transactions send ./transactions/rewards/setup_account.cdc --signer seller-account`
   1. Setup FUSD for seller `flow transactions send ./transactions/fusd/setup_account.cdc --signer seller-account`
   1. Setup Marketplace for seller `flow transactions send ./transactions/marketplace/setup_account.cdc --signer seller-account`
1. Create buyer account `flow accounts create --key 7c181e2f6d5f610c500fee438b7b817c81cea296292e2c88debdd549011ede73e1478c87dd9bfcfbb60d2699d7df6a6d75120b7b4ca09343e6c279f2ce8ee9d5`
   1. Setup Rewards for buyer `flow transactions send ./transactions/rewards/setup_account.cdc --signer buyer-account`
   1. Setup FUSD for buyer `flow transactions send ./transactions/fusd/setup_account.cdc --signer buyer-account`
   1. Setup Marketplace for buyer `flow transactions send ./transactions/marketplace/setup_account.cdc --signer buyer-account`

## Mint & Distribute tokens

1. Create a reward `flow transactions send ./transactions/rewards/admin/create_reward.cdc --arg String:foobar --arg UInt32:1337`
1. Mint an NFT for seller `flow transactions send ./transactions/rewards/admin/mint_nft.cdc --arg UInt32:1 --arg Address:01cf0e2f2f715450`

## FUSD

1. Mint some FUSD for the buyer `flow transactions send ./transactions/fusd/mint_tokens.cdc --arg Address:01cf0e2f2f715450 --arg UFix64:69696969.0`

Everything up until here has been done already and is saved in the persisted emulator chain

# Check status

1. Check the created rewards `flow scripts execute ./scripts/rewards/get_all_rewards.cdc`
1. Check the NFTs in the seller collection `flow scripts execute ./scripts/rewards/get_collection_ids.cdc --arg Address:01cf0e2f2f715450`
1. Check buyers FUSD balance `flow scripts execute ./scripts/fusd/get_balance.cdc --arg Address:01cf0e2f2f715450`

### Seller

Address: `01cf0e2f2f715450` Todo: Create seller account

1. Sell the NFT `flow transactions send ./transactions/marketplace/sell_market_item.cdc --arg UInt64:1 --arg UFix64:1337.0`
1. Check items for sale `flow scripts execute ./scripts/marketplace/get_collection_ids.cdc --arg Address:f8d6e0586b0a20c7`

### Buyer

Address: `01cf0e2f2f715450`

1. Buy item
1. Check sellers sales (should be empty) `flow scripts execute ./scripts/marketplace/get_collection_ids.cdc --arg Address:f8d6e0586b0a20c7`
1. Check rewards collection (should have 1) `flow scripts execute ./scripts/collections/get_collection_ids.cdc --arg Address:01cf0e2f2f715450`
1. Check seller FUSD balance `flow scripts execute ./scripts/fusd/get_balance.cdc --arg Address:f8d6e0586b0a20c7`
