import { Address, UFix64 } from "@onflow/types";
import {
  getContractAddress,
  getTransactionCode,
  sendTransaction,
  executeScript,
  getScriptCode,
} from "flow-js-testing";
import { getAddressMap, toUFix64 } from "./helpers";

export async function setupFUSDVault(
  account: any
): Promise<[{ events: any[] }]> {
  return sendTransaction({
    code: await getTransactionCode({
      name: "fusd/setup_account",
    }),
    signers: [account],
  });
}

export async function mintFUSD(
  receiver: any,
  amount: Number
): Promise<[{ events: any[] }]> {
  const fusdAdmin = await getContractAddress("FUSD");
  return sendTransaction({
    code: await getTransactionCode({
      name: "fusd/mint_tokens",
      addressMap: {},
    }),
    args: [
      [receiver, Address],
      [toUFix64(amount), UFix64],
    ],
    signers: [fusdAdmin],
  });
}

export async function getFUSDBalance(account: any): Promise<[string]> {
  const addressMap = await getAddressMap();

  return executeScript({
    code: await getScriptCode({
      name: "fusd/get_balance",
      addressMap,
    }),
    args: [[account, Address]],
  });
}
