import type { AppProps } from "next/app";
import { UserSession, AppConfig, showConnect } from "@stacks/connect-react";

const appConfig = new AppConfig(["store_write"]);
const userSession = new UserSession({ appConfig });

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <div>
      {!userSession.isUserSignedIn() ? (
        <button 
          onClick={() => 
            showConnect({
              userSession,
              appDetails: {
                name: "Bitcoin Escrow Service",
                icon: "/icon.png",
                 },
              })
          }
        >Connect Wallet</button>
      ) : (
        <p>Connected as: {userSession.loadUserData()?.profile?.stxAddress || "Unknown"}</p> // optional chain to avoid runtime error
      )}
      <Component {...pageProps} />
    </div>
  );
}

export default MyApp;
