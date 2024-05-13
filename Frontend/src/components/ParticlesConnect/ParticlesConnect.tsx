"use client";
import {
  ConnectButton,
  ModalProvider,
  useAccount,
  useNetwork,
  useParticleConnect,
  useParticleProvider,
} from "@particle-network/connect-react-ui";

import { isEVMProvider } from "@particle-network/connect";

import "@particle-network/connect-react-ui/dist/index.css";

import { Ethereum } from "@particle-network/chains";
import { useEffect } from "react";

import Web3 from "web3";

const ParticlesConnect = () => {
  return (
    <ModalProvider
      particleAuthSort={["email", "google", "twitter", "facebook"]}
      options={{
        projectId: process.env.ParticlesNetwork_ProjectId ? process.env.ParticlesNetwork_ProjectId : '',
        clientKey: process.env.ParticlesNetwork_ClientKey ? process.env.ParticlesNetwork_ClientKey : '',
        appId: process.env.ParticlesNetwork_AppId ? process.env.ParticlesNetwork_AppId : '',
        chains: [Ethereum],
        particleWalletEntry: {
          displayWalletEntry: true,
        },
      }}
      theme="auto"
    >
      <ConnectContent />
    </ModalProvider>
  );
};

const ConnectContent = () => {
  //TODO: Enable this function after adding wallet connect
  const provider = useParticleProvider();
  const account = useAccount();
  const { connect, disconnect } = useParticleConnect();
  const chain = useNetwork();

  // useEffect(() => {
  //   if (provider && isEVMProvider(provider)) {
  //     window.web3 = new Web3(provider as any);
  //   }
  // }, [provider]);

  return (
    <div>
      <ConnectButton />
    </div>
  );
};

export default ParticlesConnect;
