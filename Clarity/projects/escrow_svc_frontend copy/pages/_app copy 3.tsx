import type { AppProps } from "next/app";
import { useState } from "react";
import { StacksTestnet } from "@stacks/network";
import { UserSession, AppConfig, showConnect } from "@stacks/connect-react";
import { openContractCall } from "@stacks/connect";
import { uintCV, principalCV, bufferCVFromString, noneCV, someCV } from "@stacks/transactions";

// Configure Stacks authentication
const appConfig = new AppConfig(["store_write"]);
const userSession = new UserSession({ appConfig });
const network = new StacksTestnet();

// Contract details (Replace with actual values)
const CONTRACT_ADDRESS = "ST123..."; 
const CONTRACT_NAME = "escrow-contract"; 

function MyApp({ Component, pageProps }: AppProps) {
  const [beneficiary, setBeneficiary] = useState("");
  const [btcTxHash, setBtcTxHash] = useState("");
  const [amount, setAmount] = useState("");

  const authenticate = () => {
    showConnect({
      appDetails: { name: "Escrow DApp", icon: "https://example.com/icon.png" },
      userSession,
      onFinish: () => window.location.reload(),
    });
  };

  const callContractFunction = async (functionName: string, functionArgs: any[]) => {
    const options = {
      contractAddress: CONTRACT_ADDRESS,
      contractName: CONTRACT_NAME,
      functionName,
      functionArgs,
      network,
      appDetails: { name: "Escrow DApp", icon: "https://example.com/icon.png" },
      onFinish: (data: any) => console.log("Transaction ID:", data.txId),
    };
    await openContractCall(options);
  };

  return (
    <>
      {!userSession.isUserSignedIn() ? (
        <button onClick={authenticate}>Connect Wallet</button>
      ) : (
        <>
          <p>Connected as: {userSession.loadUserData().profile.stxAddress}</p>
        </>
      )}
      <Component {...pageProps} />
    </>
  );
}

export default MyApp;
