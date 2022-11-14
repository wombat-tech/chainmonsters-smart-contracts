import {
  deployContractByName,
  emulator,
  executeScript,
  getAccountAddress,
  getServiceAddress,
  init,
  mintFlow,
  sendTransaction,
  shallPass,
  shallResolve,
  shallRevert,
} from "@onflow/flow-js-testing";
import path from "path";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

const RARE_BUNDLE_REWARD_ID = "1";
const EPIC_BUNDLE_REWARD_ID = "2";
const LEGENDARY_BUNDLE_REWARD_ID = "3";
const RARE_ITEM_REWARD_ID = "4";
const EPIC_ITEM_REWARD_ID = "5";
const LEGENDARY_ITEM_REWARD_ID = "6";

const RARE_TIER = "0";
const EPIC_TIER = "1";
const LEGENDARY_TIER = "2";

describe("ChainmonstersFoundation", () => {
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
        [merchant, RARE_TIER, "99.0"]
      )
    );

    // Check if the BundleSold event was triggered with the right tier
    const bundleSoldEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleSold"
    );
    expect(bundleSoldEvent.data.tier).toBe(RARE_TIER);

    // Check if a token is deposited to the user's account
    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );
    expect(depositEvent.data.to).toBe(user);

    // Check if the RARE bundle supply has decreased
    const [supplies] = await executeScript("foundation/get_bundle_supply", [
      admin,
    ]);
    expect(supplies).toEqual(["4", "5", "5"]);
  });

  test("can purchase a bundle via fungible token", async () => {
    await deployContracts();

    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await setupFoundation();

    // Give user some FLOW token for the transaction
    await mintFlow(user, "10000.0");

    // Purchase Bundle
    const [result] = await shallPass(
      sendTransaction(
        "foundation/purchase_bundle",
        [admin, user],
        [LEGENDARY_TIER, "9999.0", "/storage/flowTokenVault"]
      )
    );

    // Check if the BundleSold event was triggered with the right tier
    const bundleSoldEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleSold"
    );
    expect(bundleSoldEvent.data.tier).toBe(LEGENDARY_TIER);

    // Check if a token is deposited to the user's account
    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );
    expect(depositEvent.data.to).toBe(user);

    // Check if the RARE bundle supply has decreased
    const [supplies] = await executeScript("foundation/get_bundle_supply", [
      admin,
    ]);
    expect(supplies).toEqual(["5", "5", "4"]);
  });

  test("redeems RARE bundles correctly", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Mint a bundle NFT for the user
    await shallPass(
      sendTransaction(
        "rewards/admin/mint_nft",
        [admin],
        [RARE_BUNDLE_REWARD_ID, user]
      )
    );

    // Based on the NFTs minted in `setupFoundation`
    const NEW_NFT_ID = "76";

    // Redeem Bundle
    const [result] = await shallPass(
      sendTransaction("foundation/redeem_bundle", [admin, user], [NEW_NFT_ID])
    );

    const redeemEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleRedeemed"
    );

    // Redeeming a RARE bundle, so expecting 2 NFTs
    expect(redeemEvent.data.redeemedIDs.length).toBe(2);

    for (const id of redeemEvent.data.redeemedIDs) {
      const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
        user,
        id,
      ]);

      expect(Number(rewardID)).toBeGreaterThanOrEqual(4);
    }
  });

  test("redeems EPIC bundles correctly", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Mint an EPIC bundle NFT for the user
    await shallPass(
      sendTransaction(
        "rewards/admin/mint_nft",
        [admin],
        [EPIC_BUNDLE_REWARD_ID, user]
      )
    );

    // Based on the NFTs minted in `setupFoundation`
    const NEW_NFT_ID = "76";

    // Redeem Bundle
    const [result] = await shallPass(
      sendTransaction("foundation/redeem_bundle", [admin, user], [NEW_NFT_ID])
    );

    const redeemEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleRedeemed"
    );

    expect(redeemEvent.data.redeemedIDs.length).toBe(3);

    const rewardIDs: string[] = [];

    for (const id of redeemEvent.data.redeemedIDs) {
      const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
        user,
        id,
      ]);

      rewardIDs.push(rewardID);
    }

    // Must have at least one EPIC or better reward
    expect(
      rewardIDs.some((id) => Number(id) >= Number(EPIC_ITEM_REWARD_ID))
    ).toBe(true);
  });

  test("redeems LEGENDARY bundles correctly", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Mint an EPIC bundle NFT for the user
    await shallPass(
      sendTransaction("rewards/admin/mint_nft", [admin], ["3", user])
    );

    // Based on the NFTs minted in `setupFoundation`
    const NEW_NFT_ID = "76";

    // Redeem Bundle
    const [result] = await shallPass(
      sendTransaction("foundation/redeem_bundle", [admin, user], [NEW_NFT_ID])
    );

    const redeemEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleRedeemed"
    );

    expect(redeemEvent.data.redeemedIDs.length).toBe(3);

    const rewardIDs: string[] = [];

    for (const id of redeemEvent.data.redeemedIDs) {
      const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
        user,
        id,
      ]);

      rewardIDs.push(rewardID);
    }

    // Must have at least one LEGENDARY reward
    expect(rewardIDs).toContain(LEGENDARY_ITEM_REWARD_ID);
  });

  test("rolls 69 with a seed number of 420 :kappa:", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    const [, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [RARE_TIER, "420"]
      )
    );

    expect(logs).toContain("Rolled: 69");
  });

  test("rolls 1; upgrades RARE and returns a LEGENDARY item", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for RARE item but seed 590416 rolls a 1, so upgrading to LEGENDARY
    const [result, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [RARE_TIER, "590416"]
      )
    );

    expect(logs).toContain("Rolled: 1");

    const upgradeRolledEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.UpgradeRolled"
    );

    expect(upgradeRolledEvent.data.tier).toEqual(LEGENDARY_TIER);

    const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
      user,
      upgradeRolledEvent.data.nftID,
    ]);

    expect(rewardID).toEqual(LEGENDARY_ITEM_REWARD_ID);
  });

  test("rolls 1; upgrades EPIC and returns a LEGENDARY item", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for EPIC item but seed 590416 rolls a 1, so upgrading to LEGENDARY
    const [result, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [EPIC_TIER, "590416"]
      )
    );

    expect(logs).toContain("Rolled: 1");

    const upgradeRolledEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.UpgradeRolled"
    );

    expect(upgradeRolledEvent.data.tier).toEqual(LEGENDARY_TIER);

    const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
      user,
      upgradeRolledEvent.data.nftID,
    ]);

    expect(rewardID).toEqual(LEGENDARY_ITEM_REWARD_ID);
  });

  test("rolls 6; upgrades RARE and returns an EPIC item", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for RARE item but seed 812409 rolls a 6, so upgrading to EPIC
    const [result, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [RARE_TIER, "812409"]
      )
    );

    expect(logs).toContain("Rolled: 6");

    const upgradeRolledEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.UpgradeRolled"
    );

    expect(upgradeRolledEvent.data.tier).toEqual(EPIC_TIER);

    const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
      user,
      upgradeRolledEvent.data.nftID,
    ]);

    expect(rewardID).toEqual(EPIC_ITEM_REWARD_ID);
  });

  test("rolls 66; returns a RARE item on RARE roll", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for RARE item but seed 812409 rolls a 6, so upgrading to EPIC
    const [result, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [RARE_TIER, "1"]
      )
    );

    expect(logs).toContain("Rolled: 66");

    const upgradeRolledEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.UpgradeRolled"
    );

    // No upgrade event
    expect(upgradeRolledEvent).toBeUndefined();

    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );

    const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
      user,
      depositEvent.data.id,
    ]);

    // Deposited a RARE item
    expect(rewardID).toEqual(RARE_ITEM_REWARD_ID);
  });

  test("rolls 66; returns a EPIC item on EPIC roll", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for RARE item but seed 812409 rolls a 6, so upgrading to EPIC
    const [result, , logs] = await shallPass(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [EPIC_TIER, "1"]
      )
    );

    expect(logs).toContain("Rolled: 66");

    const upgradeRolledEvent = result.events.find(
      (e) =>
        e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.UpgradeRolled"
    );

    // No upgrade event
    expect(upgradeRolledEvent).toBeUndefined();

    const depositEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersRewards.Deposit"
    );

    const [rewardID] = await executeScript("rewards/get_nft_rewardID", [
      user,
      depositEvent.data.id,
    ]);

    // Deposited a RARE item
    expect(rewardID).toEqual(EPIC_ITEM_REWARD_ID);
  });

  test("can not roll for LEGENDARY item", async () => {
    const admin = await getServiceAddress();
    const user = await getAccountAddress("Alice");

    await deployContracts();

    await setupFoundation();

    // Rolling for RARE item but seed 812409 rolls a 6, so upgrading to EPIC
    const [, error] = await shallRevert(
      sendTransaction(
        "foundation/__tests__/test_redemption",
        [admin, user],
        [LEGENDARY_TIER, "1"]
      )
    );

    expect(error).toContain("Can't roll for LEGENDARY upgrade");
  });

  test("can create a new admin", async () => {
    const admin = await getServiceAddress();
    const newAdmin = await getAccountAddress("Alice");
    const user = await getAccountAddress("Bob");

    await deployContracts();

    await setupFoundation();

    // Create a new admin
    await shallPass(
      sendTransaction("foundation/create_admin", [admin, newAdmin])
    );

    // Give user some FLOW token for the transaction
    await mintFlow(user, "10000.0");

    // Purchase bundle
    const [result] = await shallPass(
      sendTransaction(
        "foundation/purchase_bundle",
        [newAdmin, user],
        [LEGENDARY_TIER, "9999.0", "/storage/flowTokenVault"]
      )
    );

    const bundleSoldEvent = result.events.find(
      (e) => e.type === "A.f8d6e0586b0a20c7.ChainmonstersFoundation.BundleSold"
    );

    const newNFTID = bundleSoldEvent.data.nftID;

    // Redeem Bundle
    await shallPass(
      sendTransaction("foundation/redeem_bundle", [newAdmin, user], [newNFTID])
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
      args: ["1", "2", "3"],
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

  const [supplies] = await executeScript("foundation/get_bundle_supply", [
    admin,
  ]);

  expect(supplies).toEqual(["5", "5", "5"]);
}
