import {
  deployContractByName,
  emulator,
  getAccountAddress,
  getServiceAddress,
  init,
  mintFlow,
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
    await emulator.start({ logging: true });
  });

  afterEach(async () => {
    await emulator.stop();
  });

  test("can deploy the contract", async () => {
    await deployContracts();
  });

  test("can purchase a bundle via dapperwallet", async () => {
    await deployContracts();

    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");
    const merchant = await getAccountAddress("Bob");
    const ducAdmin = await getAccountAddress("Chainmonster");

    await setupFoundation();

    // Set up test DUC vault
    await shallPass(
      sendTransaction(
        "dapperwallet/__tests__/setup_account",
        [merchant],
        [ducAdmin]
      )
    );

    // Purchase Bundle
    const [result] = await shallPass(
      sendTransaction(
        "dapperwallet/purchase_bundle",
        [admin, ducAdmin, user],
        [merchant, "0", "99.0"]
      )
    );

    // Check if the BundleSold event was triggered with the right tier
    const bundleSoldEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleSold"
    );
    expect(bundleSoldEvent.data.tier).toBe("0");

    // Check if a token is deposited to the user's account
    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );
    expect(depositEvent.data.to).toBe(user);
  });

  test("can purchase a bundle via fungible token", async () => {
    await deployContracts();

    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await setupFoundation();

    // Give user some FLOW token for the transaction
    await mintFlow(user, "100.0");

    // Purchase Bundle
    const [result] = await shallPass(
      sendTransaction(
        "foundation/purchase_bundle",
        [admin, user],
        ["0", "99.0", "/storage/flowTokenVault"]
      )
    );

    // Check if the BundleSold event was triggered with the right tier
    const bundleSoldEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleSold"
    );
    expect(bundleSoldEvent.data.tier).toBe("0");

    // Check if a token is deposited to the user's account
    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );
    expect(depositEvent.data.to).toBe(user);
  });

  test.only("can redeem a bundle", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Mint a bundle NFT for the user
    await shallPass(
      sendTransaction("rewards/admin/mint_nft", [admin], ["1", user])
    );

    // Based on the NFTs minted in `setupFoundation`
    const NEW_NFT_ID = "76";

    emulator.setLogging(true);

    // Redeem Bundle
    const [result] = await shallPass(
      sendTransaction("foundation/redeem_bundle", [admin, user], [NEW_NFT_ID])
    );

    emulator.setLogging(false);

    //console.log(result);
  });

  // test("can claim a bundle", async () => {
  //   await deployContracts();

  //   const admin = await getServiceAddress();
  //   const user = await getAccountAddress("Alice");

  //   // Set up account
  //   await shallPass(sendTransaction("rewards/setup_account", [admin]));
  //   await shallPass(sendTransaction("rewards/setup_account", [user]));

  //   // Create rewards
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["First Reward", "10"]
  //     )
  //   );
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["Second Reward", "10"]
  //     )
  //   );
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["Third Reward", "10"]
  //     )
  //   );

  //   // Create bundles
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["First Bundle", "10"]
  //     )
  //   );
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["Second Bundle", "10"]
  //     )
  //   );
  //   await shallPass(
  //     sendTransaction(
  //       "rewards/admin/create_reward",
  //       [admin],
  //       ["Third Bundle", "10"]
  //     )
  //   );

  //   const REWARD_IDS = [1, 2, 3];
  //   const BUNDLE_IDS = [4, 5, 6];

  //   // Mint Rewards
  //   for (const id of REWARD_IDS) {
  //     await shallPass(
  //       sendTransaction(
  //         "rewards/admin/batch_mint_reward",
  //         [admin],
  //         [id.toString(), "10", admin]
  //       )
  //     );
  //   }

  //   // Mint 1 bundle for user
  //   const [result] = await shallPass(
  //     sendTransaction(
  //       "rewards/admin/mint_nft",
  //       [admin],
  //       [BUNDLE_IDS[0].toString(), user]
  //     )
  //   );

  //   const newNFTId: number = result.events.find(
  //     (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.NFTMinted"
  //   ).data.NFTID;

  //   // Claim 1 bundle
  //   await shallPass(
  //     sendTransaction(
  //       "foundation/claim_bundle_nft",
  //       [admin, user],
  //       [newNFTId.toString(), BUNDLE_IDS.map(String)]
  //     )
  //   );
  // });
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

  await shallResolve(
    deployContractByName({
      name: "lib/PRNG",
      to,
    })
  );

  await shallResolve(
    deployContractByName({
      name: "ChainmonstersRewards",
      to,
    })
  );

  return shallResolve(
    deployContractByName({
      name: "ChainmonstersFoundation",
      // @TODO: Fix this
      //args: [["1", "2", "3"]],
      args: [],
    })
  );
}

async function setupFoundation() {
  const admin = await getServiceAddress();
  const user = await getAccountAddress("Alice");

  // Set up account
  await shallPass(sendTransaction("rewards/setup_account", [user]));

  // Create Bundle & Item Rewards
  await shallPass(
    sendTransaction("foundation/__tests__/create_rewards", [admin])
  );

  // Mint Bundles and rewards
  await shallPass(
    sendTransaction("foundation/__tests__/provide_items", [admin], ["5"], 9999)
  );
}
