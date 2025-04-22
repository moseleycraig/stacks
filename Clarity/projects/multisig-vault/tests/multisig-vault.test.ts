
import { describe, expect, it } from "vitest";

const contractName = "multisig-vault";

const defaultStxVaultAmount = 5000;
const defaultMembers = [
  "deployer",
  "wallet_1",
  "wallet_2",
  "wallet_3",
  "wallet_4",
];
const defaultVotesRequired = defaultMembers.length - 1;

type InitContractOptions = {
  chain: Chain;
  accounts: Map<string, Account>;
  members?: Array<string>;
  votesRequired?: number;
  stxVaultAmount?: number;
};

function initContract(
  {
    chain,
    accounts,
    members = defaultMembers,
    votesRequired = defaultVotesRequired,
    stxVaultAmount = defaultStxVaultAmount,
  }: InitContractOptions,
) {
  const deployer = accounts.get("deployer")!;
  const contractPrincipal = `${deployer.address}.${contractName}`;
  const memberAccounts = members.map((name) => accounts.get(name)!);
  const nonMemberAccounts = Array.from(accounts.keys()).filter((key) =>
    !members.includes(key)
  ).map((name) => accounts.get(name)!);
  const startBlock = chain.mineBlock([
    Tx.contractCall(contractName, "start", [
      types.list(
        memberAccounts.map((account) => types.principal(account.address)),
      ),
      types.uint(votesRequired),
    ], deployer.address),
    Tx.contractCall(
      contractName,
      "deposit",
      [types.uint(stxVaultAmount)],
      deployer.address,
    ),
  ]);
  return {
    deployer,
    contractPrincipal,
    memberAccounts,
    nonMemberAccounts,
    startBlock,
  };
}
