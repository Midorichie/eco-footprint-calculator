import { Clarinet, Tx, Chain, Account } from "https://deno.land/x/clarinet@v0.19.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.114.0/testing/asserts.ts";

Clarinet.test({
  name: "add-entry and get-total work",
  fn: async (chain: Chain, accounts: Map<string, Account>) => {
    const deployer = accounts.get("deployer")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "eco-footprint",
        "add-entry",
        ["\"cycling\"", "u10"],
        deployer.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectUint(10);

    block = chain.mineBlock([
      Tx.contractCall(
        "eco-footprint",
        "add-entry",
        ["\"walking\"", "u5"],
        deployer.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectUint(15);

    const total = chain.callReadOnlyFn(
      "eco-footprint",
      "get-total",
      [deployer.address],
      deployer.address
    );
    total.result.expectOk().expectUint(15);
  },
});
