import type { AppProps } from 'next/app';
import { Connect } from '@stacks/connect-react';
import { StacksTestnet } from '@stacks/network';

const network = new StacksTestnet();

// The Connect component is wrapped around your entire app to provide Stacks authentication throughout

function MyApp({ Component, pageProps }: AppProps) {
    return (
      <Connect
        authOptions={{
          appDetails: {
            name: 'Bitcoin Escrow Service',
            icon: '/icon.png',
          },
          redirectTo: '/',
          network: network,
        }}
      >
        <Component {...pageProps} />
      </Connect>
    );
}

export default MyApp;
