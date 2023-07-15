import { ethers } from 'ethers';
import type { ComputedRef } from 'vue';
import { computed } from 'vue';

import { GaslessVoting__factory, type DAOv1, type GaslessVoting, type PollACLv1 } from '@oasisprotocol/demo-voting-backend';
import { DAOv1__factory, PollACLv1__factory } from '@oasisprotocol/demo-voting-backend';

import { useEthereumStore } from './stores/ethereum';

export type { DAOv1, GaslessVoting } from '@oasisprotocol/demo-voting-backend';

const provider = new ethers.providers.JsonRpcProvider(
  import.meta.env.VITE_WEB3_GATEWAY,
  'any',
);


export const staticDAOv1 = DAOv1__factory.connect(import.meta.env.VITE_DAO_V1_ADDR!, provider);

export function useDAOv1(): ComputedRef<DAOv1> {
  const eth = useEthereumStore();
  const addr = import.meta.env.VITE_DAO_V1_ADDR!;
  return computed(() => {
    return DAOv1__factory.connect(addr, eth.signer ?? eth.provider);
  });
}

export async function usePollACLv1(): Promise<ComputedRef<PollACLv1>> {
  const eth = useEthereumStore();
  const dao = useDAOv1().value;

  const ref = PollACLv1__factory.connect(await dao.getACL(), eth.signer ?? eth.provider);
  return computed(() => { return ref });
}

export async function useGaslessVoting(): Promise<ComputedRef<GaslessVoting|undefined>> {
  const eth = useEthereumStore();
  const dao = useDAOv1().value;
  const proxyVoter = await dao.proxyVoter();

  let ref : undefined | GaslessVoting = undefined;

  if( proxyVoter != ethers.constants.AddressZero ) {
    ref = GaslessVoting__factory.connect(proxyVoter, eth.signer ?? eth.provider);
    const sig = ref.interface.getSighash(ref.interface.getFunction('makeVoteTransaction'));
    const isGaslessVoting = await ref.supportsInterface(sig);
    if( ! isGaslessVoting ) {
      console.log('Proxy Voter', proxyVoter, 'is not a gasless voting contract!');
      ref = undefined;
    }
    else {
      console.log('Proxy Voter', proxyVoter, 'supports GaslessVoting interface');
    }
  }

  return computed(() => { return ref });
}
