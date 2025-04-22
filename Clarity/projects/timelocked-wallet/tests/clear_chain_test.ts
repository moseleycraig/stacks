Clarinet.test({
  name: "Unlock height cannot be in the past",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const beneficiary = accounts.get("wallet_1")!;
    const targetBlockHeight = 10;
    const amount = 10;

    // Advance the chain until the unlock height plus one
    chain.mineEmptyBlockUntil(targetBlockHeight + 1);

    // Reset the chain to the initial state
    chain.clear();

    // Now try the lock operation
    const block = chain.mineBlock([
      Tx.contractCall("timelocked-wallet", "lock", [
        types.principal(beneficiary.address),
        types.uint(targetBlockHeight),
        types.uint(amount),
      ], deployer.address),
    ]);

    // The second lock should now succeed
    block.receipts[0].result.expectOk().expectBool(true);
  },
});
