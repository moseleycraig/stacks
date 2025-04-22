import '../styles/globals.css';
import { ClientProvider } from '@micro-stacks/react';
import { useCallback } from 'react';
import { destroySession, saveSession } from '../common/fetchers';

import type { AppProps } from 'next/app';
import type { ClientConfig } from '@micro-stacks/client';

function MyApp({ Component, pageProps }: AppProps) {
  const onPersistState: ClientConfig['onPersistState'] = useCallback(
    async (dehydratedState: string) => {
      await saveSession(dehydratedState);
    },
    []
  );

  const onSignOut: ClientConfig['onSignOut'] = useCallback(async () => {
    await destroySession();
  }, []);

  const network = new StacksMocknet(); // this is for DevNet, not TestNet, see _app.tsx

  // notice the return matches one of the imports
  
  return (
    <ClientProvider
      appName="Nextjs + Microstacks"
      appIconUrl="/vercel.png"
      dehydratedState={pageProps?.dehydratedState}
      onPersistState={onPersistState}
      onSignOut={onSignOut}
      network={network}
    >
      <Component {...pageProps} />
    </ClientProvider>
  );
}

export default MyApp;
