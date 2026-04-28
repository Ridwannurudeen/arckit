import type { Address, Chain } from 'viem';

export const ARC_TESTNET_CHAIN_ID = 5042002;

export const arcTestnet = {
  id: ARC_TESTNET_CHAIN_ID,
  name: 'Arc Testnet',
  nativeCurrency: { name: 'USDC', symbol: 'USDC', decimals: 6 },
  rpcUrls: {
    default: { http: ['https://rpc.testnet.arc.network'] },
    public: { http: ['https://rpc.testnet.arc.network'] },
  },
  blockExplorers: {
    default: { name: 'Arcscan', url: 'https://testnet.arcscan.app' },
  },
  testnet: true,
} as const satisfies Chain;

export type Network = 'testnet';

export type ContractAddresses = {
  agenticCommerce: Address;
  identityRegistry: Address;
  reputationRegistry: Address;
  validationRegistry: Address;
  usdc: Address;
};

export const ADDRESSES: Record<Network, ContractAddresses> = {
  testnet: {
    agenticCommerce: '0x0747EEf0706327138c69792bF28Cd525089e4583',
    identityRegistry: '0x8004A818BFB912233c491871b3d84c89A494BD9e',
    reputationRegistry: '0x8004B663056A597Dffe9eCcC1965A193B7388713',
    validationRegistry: '0x8004Cb1BF31DAf7788923b405b754f57acEB4272',
    usdc: '0x3600000000000000000000000000000000000000',
  },
};

export const USDC_DECIMALS = 6;
