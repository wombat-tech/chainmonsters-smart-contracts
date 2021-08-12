import {
  getServiceAddress,
  executeScript,
  getScriptCode,
} from "flow-js-testing";

export function toUFix64(num: Number) {
  if (Number.isInteger(num)) {
    return num + ".0";
  }

  return num.toString();
}

export async function getAddressMap(to?: any) {
  const account = to ?? (await getServiceAddress());

  return {
    NonFungibleToken: account,
    FUSD: account,
    ChainmonstersProducts: account,
  };
}

export function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getBlockTime() {
  return executeScript({
    code: await getScriptCode({
      name: "get_block_time",
    }),
  });
}
