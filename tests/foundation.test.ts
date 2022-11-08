import {
  deployContractByName,
  emulator,
  getAccountAddress,
  getServiceAddress,
  init,
  sendTransaction,
  shallPass,
  shallResolve,
} from "@onflow/flow-js-testing";
import path from "path";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe("ChainmonstersFoundationBundles", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../");

    await init(basePath);
    await emulator.start();
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
  });

  test("can purchase a bundle", async () => {
    await deployContracts();

    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");
    const merchant = await getAccountAddress("Bob");
    const ducAdmin = await getAccountAddress("Chainmonster");

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [user]));

    // Set up test DUC vault
    await shallPass(
      sendTransaction(
        "dapperwallet/__tests__/setup_account",
        [merchant],
        [ducAdmin]
      )
    );

    // Create reward
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["First Bundle", "10"]
      )
    );

    await shallPass(
      sendTransaction(
        "dapperwallet/purchase_nft",
        [admin, ducAdmin, user],
        [merchant, "1", "99.0"]
      )
    );
  });

  test("can claim a bundle", async () => {
    await deployContracts();

    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    // Set up account
    await shallPass(sendTransaction("rewards/setup_account", [admin]));
    await shallPass(sendTransaction("rewards/setup_account", [user]));

    // Create rewards
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["First Reward", "10"]
      )
    );
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["Second Reward", "10"]
      )
    );
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["Third Reward", "10"]
      )
    );

    // Create bundles
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["First Bundle", "10"]
      )
    );
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["Second Bundle", "10"]
      )
    );
    await shallPass(
      sendTransaction(
        "rewards/admin/create_reward",
        [admin],
        ["Third Bundle", "10"]
      )
    );

    const REWARD_IDS = [1, 2, 3];
    const BUNDLE_IDS = [4, 5, 6];

    // Mint Rewards
    for (const id of REWARD_IDS) {
      await shallPass(
        sendTransaction(
          "rewards/admin/batch_mint_reward",
          [admin],
          [id.toString(), "10", admin]
        )
      );
    }

    // Mint 1 bundle for user
    const [result] = await shallPass(
      sendTransaction(
        "rewards/admin/mint_nft",
        [admin],
        [BUNDLE_IDS[0].toString(), user]
      )
    );

    const newNFTId: number = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.NFTMinted"
    ).data.NFTID;

    // Claim 1 bundle
    await shallPass(
      sendTransaction(
        "foundation/claim_bundle_nft",
        [admin, user],
        [newNFTId.toString(), BUNDLE_IDS.map(String)]
      )
    );
  });
});

async function deployContracts(): Promise<[{ events: any[] }]> {
  const to = await getServiceAddress();
  const ducAdmin = await getAccountAddress("Chainmonster");

  await shallResolve(
    deployContractByName({
      name: "lib/TokenForwarding",
      to,
    })
  );

  await shallResolve(
    deployContractByName({
      name: "lib/DapperUtilityCoin",
      to: ducAdmin,
    })
  );

  await shallResolve(
    deployContractByName({
      name: "lib/NonFungibleToken",
      to,
    })
  );

  await shallResolve(
    deployContractByName({
      name: "lib/MetadataViews",
      to,
    })
  );

  return shallResolve(
    deployContractByName({
      name: "ChainmonstersRewards",
      to,
    })
  );
}
