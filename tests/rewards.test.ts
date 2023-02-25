import {
  deployContractByName,
  emulator,
  executeScript,
  getAccountAddress,
  getServiceAddress,
  init,
  sendTransaction,
  shallPass,
} from "@onflow/flow-js-testing";
import path from "path";
import rewardsMetadata from "../data/rewardsMetadata.json";
import seasonsMetadata from "../data/seasonsMetadata.json";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe("ChainmonstersRewards", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../");

    await init(basePath);
    await emulator.start({ logging: true });
  });

  afterEach(async () => {
    await emulator.stop();
  });

  test("should deploy the contracts", async () => {
    const [{ events }] = await deployContracts();

    const initEvent = events.find((e) =>
      (e.type as string).endsWith("ChainmonstersRewards.ContractInitialized")
    );

    expect(initEvent).toBeDefined();
  });

  test("can set metadata", async () => {
    const signer = await getServiceAddress();

    await shallPass(
      sendTransaction(
        "rewardsMetadata/setRewardsMetadata",
        [signer],
        [rewardsMetadata]
      )
    );

    await shallPass(
      sendTransaction(
        "rewardsMetadata/setSeasonsMetadata",
        [signer],
        [seasonsMetadata]
      )
    );
  });

  test("can mint reward & show metadata", async () => {
    await deployContracts();

    const signer = await getServiceAddress();

    // Set rewards metadata
    await shallPass(
      sendTransaction(
        "rewardsMetadata/setRewardsMetadata",
        [signer],
        [rewardsMetadata]
      )
    );

    // Set seasons metadata
    await shallPass(
      sendTransaction(
        "rewardsMetadata/setSeasonsMetadata",
        [signer],
        [seasonsMetadata]
      )
    );

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [signer]));

    // Create reward
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [signer],
        ["First reward", "1000"]
      )
    );

    // Mint NFT
    await shallPass(
      sendTransaction("rewards/admin/mint_nft", [signer], ["1", signer])
    );

    const [nftData] = await executeScript({
      name: "rewards/get_nft_view",
      args: [signer, "1"],
    });

    expect(nftData).toEqual({
      name: "Chainmon Designer",
      description:
        "Help us design a Chainmon. Send us ideas or sketches and work with our team to bring it to life! You also receive the very first one of its kind including all variations in your team! If you don't feel like designing then choose one of our upcoming in-house designs and claim it instead!",
      thumbnail: "https://chainmonsters.com/images/rewards/1.png",
      owner: "0xf8d6e0586b0a20c7",
      type: "A.f8d6e0586b0a20c7.ChainmonstersRewards.NFT",
      royalties: [
        {
          receiver: {
            address: "0xf8d6e0586b0a20c7",
            borrowType: {
              authorized: false,
              kind: "Reference",
              type: {
                kind: "Restriction",
                restrictions: [
                  {
                    fields: [
                      {
                        id: "uuid",
                        type: {
                          kind: "UInt64",
                        },
                      },
                    ],
                    initializers: [],
                    kind: "ResourceInterface",
                    type: "",
                    typeID: "A.ee82856bf20e2aa6.FungibleToken.Receiver",
                  },
                ],
                type: {
                  kind: "AnyResource",
                },
                typeID:
                  "AnyResource{A.ee82856bf20e2aa6.FungibleToken.Receiver}",
              },
            },
            path: {
              type: "Path",
              value: {
                domain: "public",
                identifier: "GenericFTReceiver",
              },
            },
          },
          cut: "0.05000000",
          description: "Chainmonsters Platform Cut",
        },
      ],
      externalURL: "https://chainmonsters.com/rewards/1",
      serialNumber: "1",
      collectionPublicPath: {
        domain: "public",
        identifier: "ChainmonstersRewardCollection",
      },
      collectionStoragePath: {
        domain: "storage",
        identifier: "ChainmonstersRewardCollection",
      },
      collectionProviderPath: {
        domain: "private",
        identifier: "ChainmonstersRewardsCollectionProvider",
      },
      collectionPublic:
        "&A.f8d6e0586b0a20c7.ChainmonstersRewards.Collection{A.f8d6e0586b0a20c7.ChainmonstersRewards.ChainmonstersRewardCollectionPublic}",
      collectionPublicLinkedType:
        "&A.f8d6e0586b0a20c7.ChainmonstersRewards.Collection{A.f8d6e0586b0a20c7.ChainmonstersRewards.ChainmonstersRewardCollectionPublic,A.f8d6e0586b0a20c7.NonFungibleToken.CollectionPublic,A.f8d6e0586b0a20c7.NonFungibleToken.Receiver,A.f8d6e0586b0a20c7.MetadataViews.ResolverCollection}",
      collectionProviderLinkedType:
        "&A.f8d6e0586b0a20c7.ChainmonstersRewards.Collection{A.f8d6e0586b0a20c7.ChainmonstersRewards.ChainmonstersRewardCollectionPublic,A.f8d6e0586b0a20c7.NonFungibleToken.CollectionPublic,A.f8d6e0586b0a20c7.NonFungibleToken.Provider,A.f8d6e0586b0a20c7.MetadataViews.ResolverCollection}",
      collectionName: "Chainmonsters Rewards",
      collectionDescription:
        "Chainmonsters is a massive multiplayer online RPG where you catch, battle, trade, explore, and combine different types of monsters and abilities to create strong chain reactions! No game subscription required. Explore the vast lands of Ancora together with your friends on Steam, iOS and Android!",
      collectionExternalURL: "https://chainmonsters.com",
      collectionSquareImage: "https://chainmonsters.com/images/chipleaf.png",
      collectionBannerImage: "https://chainmonsters.com/images/bg.jpg",
      collectionSocials: {
        discord: "https://discord.gg/chainmonsters",
        twitter: "https://twitter.com/chainmonsters",
      },
      edition: null,
      traits: null,
      medias: null,
      license: null,
    });
  });

  test("can migrate an item", async () => {
    await deployContracts();

    const Alice = await getAccountAddress("Alice");

    const admin = await getServiceAddress();

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [Alice]));

    // Create reward
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["First reward", "1000"]
      )
    );

    // Mint NFTs
    await shallPass(
      sendTransaction(
        "rewards/admin/batch_mint_reward",
        [admin],
        ["1", "100", Alice],
        9999
      )
    );

    const [beforeSupply] = await executeScript(
      "rewards/get_collection_supply",
      [Alice]
    );

    expect(beforeSupply).toEqual("100");

    // Migrate collection
    const [{ events }] = await shallPass(
      sendTransaction(
        "rewards/migration/migrate_collection",
        [Alice, admin],
        ["123", "0x1337"],
        9999
      )
    );

    const migrationEvents = events.filter((e) =>
      e.type.endsWith("ChainmonstersRewards.ItemMigrated")
    );

    // Has 100 withdraw events
    expect(migrationEvents).toHaveLength(100);
    // Has correct data
    expect(migrationEvents[0].data.playerId).toEqual("123");
    expect(migrationEvents[0].data.imxWallet).toEqual("0x1337");
    expect(migrationEvents[0].data.rewardID).toEqual("1");
    expect(migrationEvents[0].data.serialNumber).toEqual("65");

    const [afterSupply] = await executeScript("rewards/get_collection_supply", [
      Alice,
    ]);

    expect(afterSupply).toEqual("0");
  });

  test("can migrate collections over 300 nfts", async () => {
    await deployContracts();

    const Alice = await getAccountAddress("Alice");

    const admin = await getServiceAddress();

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [Alice]));

    // Create reward
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["First reward", "1000"]
      )
    );

    // Mint NFTs
    await shallPass(
      sendTransaction(
        "rewards/admin/batch_mint_reward",
        [admin],
        ["1", "200", Alice],
        9999
      )
    );

    await shallPass(
      sendTransaction(
        "rewards/admin/batch_mint_reward",
        [admin],
        ["1", "200", Alice],
        9999
      )
    );

    await shallPass(
      sendTransaction(
        "rewards/admin/batch_mint_reward",
        [admin],
        ["1", "200", Alice],
        9999
      )
    );

    const [beforeSupply] = await executeScript(
      "rewards/get_collection_supply",
      [Alice]
    );

    expect(beforeSupply).toEqual("600");

    // Migrate collection
    const [{ events }] = await shallPass(
      sendTransaction(
        "rewards/migration/migrate_collection",
        [Alice, admin],
        ["123", "0x1337"],
        9999
      )
    );

    const migrationEvents = events.filter((e) =>
      e.type.endsWith("ChainmonstersRewards.ItemMigrated")
    );

    // Has 300 withdraw events
    expect(migrationEvents).toHaveLength(300);
    // Has correct data
    expect(migrationEvents[0].data.playerId).toEqual("123");
    expect(migrationEvents[0].data.imxWallet).toEqual("0x1337");
    expect(migrationEvents[0].data.rewardID).toEqual("1");
    expect(migrationEvents[0].data.serialNumber).toEqual("559");

    const [afterSupply] = await executeScript("rewards/get_collection_supply", [
      Alice,
    ]);

    expect(afterSupply).toEqual("300");
  });
});

async function deployContracts(): Promise<[{ events: any[] }]> {
  const to = await getServiceAddress();

  await shallPass(
    deployContractByName({
      name: "lib/NonFungibleToken",
      to,
    })
  );

  await shallPass(
    deployContractByName({
      name: "lib/MetadataViews",
      to,
    })
  );

  return shallPass(
    deployContractByName({
      name: "ChainmonstersRewards",
      to,
    })
  );
}
