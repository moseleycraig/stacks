import '../styles/globals.css';
import type { AppProps } from 'next/app';
import { ClientProvider } from '@micro-stacks/react';
import { useCallback } from 'react';
import { StacksMocknet} from "micro-stacks/network";
import { destroySession, saveSession } from '../common/fetchers';

// defaults to DevNet, calls will be much faster
// TestNet runs at the normal block mining times ~ 10 minutes

function MyApp({ Component, pageProps }: AppProps) {
  const network = new StacksMocknet();

  return (
    <ClientProvider
      appName="Blockpost-frontend"
      appIconUrl="/vercel.png"
      network={network}
    >
      <Component {...pageProps} />
    </ClientProvider>
  );
}

export default MyApp;
