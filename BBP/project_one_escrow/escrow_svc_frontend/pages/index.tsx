import { useState } from "react";
import { uintCV, principalCV, bufferCVFromString, noneCV, someCV } from "@stacks/transactions";
import { openContractCall } from "@stacks/connect";
import { StacksTestnet } from "@stacks/network";

const CONTRACT_ADDRESS = "ST2Q2N5ZA8M6G7HKR0V45R7ZVX99A93T06W1PV0FW"; // use Leather wallet address 1
const CONTRACT_NAME = "escrow-contract";
const network = new StacksTestnet();

export default function Escrow() {
  const [beneficiary, setBeneficiary] = useState("");
  const [btcTxHash, setBtcTxHash] = useState("");
  const [amount, setAmount] = useState("");

  const callContractFunction = async (functionName: string, functionArgs: any[]) => {
    const options = {
      contractAddress: CONTRACT_ADDRESS,
      contractName: CONTRACT_NAME,
      functionName,
      functionArgs,
      network,
      appDetails: { name: "Escrow DApp", icon: "..public/icon.png" },
      onFinish: (data: any) => console.log("Transaction ID:", data.txId),
    };
    await openContractCall(options);
  };

  return (
    <div>
      <h2>Escrow Smart Contract</h2>

      <h3>Lock Funds</h3>
      <input type="text" placeholder="Beneficiary STX Address" onChange={(e) => setBeneficiary(e.target.value)} />
      <input type="text" placeholder="Bitcoin TX Hash" onChange={(e) => setBtcTxHash(e.target.value)} />
      <input type="number" placeholder="Amount" onChange={(e) => setAmount(e.target.value)} />
      <button onClick={() => callContractFunction("lock-funds", [
        beneficiary ? someCV(principalCV(beneficiary)) : noneCV(),
        bufferCVFromString(btcTxHash),
        uintCV(parseInt(amount)),
      ])}>Lock Funds</button>

      <h3>Release Funds</h3>
      <input type="text" placeholder="Bitcoin TX Hash" onChange={(e) => setBtcTxHash(e.target.value)} />
      <button onClick={() => callContractFunction("release-funds", [bufferCVFromString(btcTxHash)])}>Release Funds</button>
    </div>
  );
}
