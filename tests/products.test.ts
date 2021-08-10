import { Address, Bool, Optional, String, UFix64, UInt32 } from "@onflow/types";
import {
  deployContract,
  emulator,
  executeScript,
  getAccountAddress,
  getContractAddress,
  getContractCode,
  getScriptCode,
  getServiceAddress,
  getTransactionCode,
  init,
  mintFlow,
  sendTransaction,
  shallPass,
  shallRevert,
} from "flow-js-testing";
import path from "path";
import { getFUSDBalance, mintFUSD, setupFUSDVault } from "./lib/FUSD";
import { getAddressMap, toUFix64 } from "./lib/helpers";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe("ChainmonstersProducts", () => {
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
    const { events } = await deployContracts();

    const initEvent = events.find((e) =>
      (e.type as string).endsWith("ChainmonstersProducts.ContractInitialized")
    );

    expect(initEvent).toBeDefined();
  });

  test("should create a product", async () => {
    const { Alice, Bob } = await setupTestUsers();
    const UNIX_START_TIME = Math.round(Date.now() / 1000);

    const { events } = await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: true,
      totalSupply: 1337,
      saleEndTime: UNIX_START_TIME,
      metadata: "Cool product 😎",
    });

    expect(events).toHaveLength(1);

    const event = events[0];

    expect(event.type).toMatch(/ChainmonstersProducts\.ProductCreated$/);
    expect(event.data).toEqual({
      productID: 1,
      price: "110.00000000",
      paymentVaultType: "A.f8d6e0586b0a20c7.FUSD.Vault",
      saleEnabled: true,
      totalSupply: 1337,
      saleEndTime: UNIX_START_TIME.toFixed(8),
      metadata: "Cool product 😎",
    });

    const product = await getProduct(1);

    expect(product).not.toBeNull();
    expect(product.sales).toBe(0);
    expect(product.price).toBe("110.00000000");
  });

  test("should be able to purchase a product", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
    });

    const { events } = await purchaseProduct(Cecilia, 1);

    const purchaseEvent = events.find((e) =>
      (e.type as string).endsWith("ChainmonstersProducts.ProductPurchased")
    );

    expect(purchaseEvent).toBeDefined();
    expect(purchaseEvent.data).toEqual({ productID: 1, buyer: Cecilia });

    expect(await getFUSDBalance(Alice)).toEqual("100.00000000");
    expect(await getFUSDBalance(Bob)).toEqual("10.00000000");
    expect(await getFUSDBalance(Cecilia)).toEqual("1227.00000000");

    expect(await hasBoughtProduct(Cecilia, 1)).toBeTruthy();

    const { sales } = await getProduct(1);

    expect(sales).toEqual(1);
  });

  test("should not be able to purchase a product that does not exist", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
    });

    await shallRevert(purchaseProductWithoutChecks(Cecilia, 123, 110));
  });

  test("should not be able to purchase with low balance", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
    });

    await shallRevert(purchaseProductWithoutChecks(Cecilia, 1, 1));
  });

  test("should only be able to purchase once if limit is 1", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      totalSupply: 1,
    });

    // Purchase product
    await purchaseProduct(Cecilia, 1);
    // This purchase should fail
    await shallRevert(purchaseProduct(Cecilia, 1));

    expect(await hasBoughtProduct(Cecilia, 1)).toBeTruthy();

    const { sales } = await getProduct(1);

    expect(sales).toEqual(1);
  });

  test("should not be able to purchase if time limit is reached", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    // Set a sale end time in the past to trigger fail condition
    const END_TIME = Math.round(Date.now() / 1000) - 1;

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEndTime: END_TIME,
    });

    const { saleEndTime } = await getProduct(1);

    expect(saleEndTime).toEqual(END_TIME.toFixed(8));

    // This purchase should fail
    await shallRevert(purchaseProduct(Cecilia, 1));

    // Script read should fail as well
    await shallRevert(hasBoughtProduct(Cecilia, 1));

    const { sales } = await getProduct(1);

    expect(sales).toEqual(0);
  });

  test("should let the admin change the products sale status", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: false,
    });

    // This purchase should fail
    await shallRevert(purchaseProduct(Cecilia, 1));

    // Enable sale
    const { events } = await setProductSaleEnabled(1, true);

    const changeEvent = events.find((e) =>
      (e.type as string).endsWith("ChainmonstersProducts.ProductSaleChanged")
    );

    expect(changeEvent).toBeDefined();
    expect(changeEvent.data).toEqual({ productID: 1, saleEnabled: true });

    // This time it should pass
    await shallPass(purchaseProduct(Cecilia, 1));

    // Disable sale again
    const { events: events2 } = await setProductSaleEnabled(1, false);

    const changeEvent2 = events2.find((e) =>
      (e.type as string).endsWith("ChainmonstersProducts.ProductSaleChanged")
    );

    expect(changeEvent2).toBeDefined();
    expect(changeEvent2.data).toEqual({ productID: 1, saleEnabled: false });

    // Should fail
    await shallRevert(purchaseProduct(Cecilia, 1));

    const { sales } = await getProduct(1);

    expect(sales).toEqual(1);
  });

  test("should not be able to set sale status on a non-existent product", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: false,
    });

    await shallRevert(setProductSaleEnabled(123, true));
  });

  test("should do nothing if enabling an already enabled product", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: true,
    });

    const { events } = await setProductSaleEnabled(1, true);

    const changeEvent = events.find((e) =>
      (e.type as string).endsWith("ChainmonstersProducts.ProductSaleChanged")
    );

    expect(changeEvent).not.toBeDefined();
  });

  test("should deposit payment in the primary vault if other cut receivers are gone", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);
    // Give Bob some dollas which we can burn :^)
    await mintFUSD(Bob, 15000000);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: true,
    });

    await sendTransaction({
      code: await getTransactionCode({
        name: "fusd/__tests__/destroy_fusd_vault.test",
      }),
      signers: [Bob],
    });

    // Bob has no FUSD vault anymore :(
    await shallRevert(getFUSDBalance(Bob));

    // Transaction should pass, even though Bob's FUSD vault is gone
    await shallPass(purchaseProduct(Cecilia, 1));

    // Alice should have received all 110 FUSD
    expect(await getFUSDBalance(Alice)).toEqual("110.00000000");
  });

  test("should fail purchase if all payment receivers are gone", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);
    // Give Bob some dollas which we can burn :^)
    await mintFUSD(Bob, 15000000);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
      saleEnabled: true,
    });

    await sendTransaction({
      code: await getTransactionCode({
        name: "fusd/__tests__/destroy_fusd_vault.test",
      }),
      signers: [Alice],
    });

    await sendTransaction({
      code: await getTransactionCode({
        name: "fusd/__tests__/destroy_fusd_vault.test",
      }),
      signers: [Bob],
    });

    // Transaction should revert
    await shallRevert(purchaseProduct(Cecilia, 1));
  });

  test("should be able to create a new admin", async () => {
    const admin = await getServiceAddress();
    const { Bob } = await setupTestUsers();

    // All hail Bob
    await sendTransaction({
      code: await getTransactionCode({
        name: "products/add_new_admin",
      }),
      signers: [admin, Bob],
    });

    await shallPass(
      createProduct({
        primaryReceiver: Bob,
        secondaryReceiver: Bob,
        signer: Bob,
      })
    );
  });

  test("should not be able to access restricted fields", async () => {
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFUSD(Cecilia, 1337);

    await createProduct({
      primaryReceiver: Alice,
      secondaryReceiver: Bob,
    });

    await purchaseProduct(Cecilia, 1);

    await shallRevert(
      sendTransaction({
        code: await getTransactionCode({
          name: "products/__tests__/manipulate_receipt_collection.test",
        }),
        signers: [Cecilia],
      })
    );
  });

  test("should allow alternative fungible token payments", async () => {
    const admin = await getContractAddress("ChainmonstersProducts");
    const { Alice, Bob, Cecilia } = await setupTestUsers();

    await mintFlow(Cecilia, "9001.0");

    await sendTransaction({
      code: await getTransactionCode({
        name: "products/__tests__/create_product_with_flow_payment.test",
      }),
      args: [[Alice, Bob, Address]],
      signers: [admin],
    });

    const { paymentVaultType } = await getProduct(1);

    expect(paymentVaultType).toMatch(/FlowToken\.Vault$/);

    await shallPass(
      sendTransaction({
        code: await getTransactionCode({
          name: "products/__tests__/purchase_product_with_flow.test",
        }),
        args: [[1, UInt32]],
        signers: [Cecilia],
      })
    );
  });
});

// -----

async function deployContracts() {
  const to = await getServiceAddress();
  const addressMap = await getAddressMap(to);

  await mintFlow(to, "1337.0");

  await deployContract({
    to,
    name: "NonFungibleToken",
    code: await getContractCode({ name: "lib/NonFungibleToken", addressMap }),
  });

  await deployContract({
    to,
    name: "FUSD",
    code: await getContractCode({ name: "lib/FUSD", addressMap }),
  });

  return deployContract({
    to,
    name: "ChainmonstersProducts",
    code: await getContractCode({ name: "ChainmonstersProducts", addressMap }),
  });
}

async function setupTestUsers() {
  await deployContracts();

  const Alice = await getAccountAddress("Alice");
  const Bob = await getAccountAddress("Bob");
  const Cecilia = await getAccountAddress("Cecilia");

  await setupFUSDVault(Alice);
  await setupFUSDVault(Bob);
  await setupFUSDVault(Cecilia);

  return { Alice, Bob, Cecilia };
}

async function createProduct({
  primaryReceiver,
  secondaryReceiver,
  saleEnabled = true,
  totalSupply,
  saleEndTime,
  metadata,
  signer,
}: {
  primaryReceiver: any;
  secondaryReceiver: any;
  saleEnabled?: boolean;
  totalSupply?: number;
  saleEndTime?: number;
  metadata?: string;
  signer?: any;
}): Promise<{ events: any[] }> {
  const productsAdmin =
    signer ?? (await getContractAddress("ChainmonstersProducts"));

  return sendTransaction({
    code: await getTransactionCode({
      name: "products/__tests__/create_product.test",
    }),
    args: [
      [primaryReceiver, Address],
      [secondaryReceiver, Address],
      [saleEnabled, Bool], // saleEnabled
      [totalSupply, Optional(UInt32)], // totalSupply
      [saleEndTime ? toUFix64(saleEndTime) : null, Optional(UFix64)], // saleEndTime
      [metadata, Optional(String)],
    ],
    signers: [productsAdmin],
  });
}

async function setProductSaleEnabled(id: number, saleEnabled: boolean) {
  const productsAdmin = await getContractAddress("ChainmonstersProducts");

  return sendTransaction({
    code: await getTransactionCode({
      name: "products/set_product_sale_enabled",
    }),
    args: [
      [id, UInt32],
      [saleEnabled, Bool],
    ],
    signers: [productsAdmin],
  });
}

async function getProduct(id: number): Promise<{
  price: number;
  paymentVaultType: string;
  sales: number;
  saleEndTime?: number;
  metadata?: string;
}> {
  const addressMap = await getAddressMap();

  return executeScript({
    code: await getScriptCode({
      name: "products/__tests__/get_product.test",
      addressMap,
    }),
    args: [[id, UInt32]],
  });
}

async function purchaseProduct(account: any, id: number) {
  return sendTransaction({
    code: await getTransactionCode({
      name: "products/purchase_product",
    }),
    args: [[id, UInt32]],
    signers: [account],
  });
}

async function purchaseProductWithoutChecks(
  account: any,
  id: number,
  amount: number
) {
  return sendTransaction({
    code: await getTransactionCode({
      name: "products/__tests__/purchase_product_with_wrong_balance.test",
    }),
    args: [
      [id, UInt32],
      [toUFix64(amount), UFix64],
    ],
    signers: [account],
  });
}

async function hasBoughtProduct(account: any, id: number) {
  const addressMap = await getAddressMap();

  return executeScript({
    code: await getScriptCode({
      name: "products/has_bought_product",
      addressMap,
    }),
    args: [
      [account, Address],
      [id, UInt32],
    ],
  });
}
