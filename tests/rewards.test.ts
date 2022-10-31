import {
  deployContractByName,
  emulator,
  getServiceAddress,
  init,
  sendTransaction,
  shallPass,
  executeScript,
  shallResolve,
} from "flow-js-testing";
import path from "path";
import rewardsMetadata from "../data/rewardsMetadata.json";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe("ChainmonstersRewards", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../");
    const port = 8080;
    const logging = false;

    await init(basePath, { port, logging });
    return emulator.start(port);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
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
  });

  test("can mint reward & show metadata", async () => {
    await deployContracts();

    const signer = await getServiceAddress();

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [signer]));

    // Create reward
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [signer],
        ["First reward", 1000]
      )
    );

    // Mint NFT
    await shallPass(
      sendTransaction("rewards/admin/mint_nft", [signer], [1, signer])
    );

    const [nftData] = await shallResolve(
      executeScript({
        name: "rewards/get_nft_view",
        args: [signer, 1],
      })
    );

    expect(nftData).toEqual({
      name: "Chainmonsters Reward #1",
      description: "A Chainmonsters Reward",
      thumbnail: "https://chainmonsters.com/images/rewards/kickstarter/1.png",
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
      serialNumber: 1,
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
        "An NFT metadata description for Chainmonsters collections",
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
});

async function deployContracts(): Promise<[{ events: any[] }]> {
  const to = await getServiceAddress();

  await deployContractByName({
    name: "lib/NonFungibleToken",
    to,
  });

  await deployContractByName({
    name: "lib/MetadataViews",
    to,
  });

  return deployContractByName({
    name: "ChainmonstersRewards",
    to,
  });
}
