import {
  http,
  type Account,
  type Address,
  type Chain,
  type PublicClient,
  type Transport,
  type WalletClient,
  createPublicClient,
  createWalletClient,
} from 'viem';
import { CommerceClient } from './clients/commerce.js';
import { IdentityClient } from './clients/identity.js';
import { ReputationClient } from './clients/reputation.js';
import { UsdcClient } from './clients/usdc.js';
import { ValidationClient } from './clients/validation.js';
import { ADDRESSES, type ContractAddresses, type Network, arcTestnet } from './constants.js';

export type ArcKitConfig = {
  /// The viem account used for write operations. Read-only mode if omitted.
  account?: Account;
  /// Network preset. Defaults to 'testnet'.
  network?: Network;
  /// Override the chain (advanced).
  chain?: Chain;
  /// Override the RPC URL.
  rpcUrl?: string;
  /// Override individual contract addresses.
  contracts?: Partial<ContractAddresses>;
  /// Bring your own viem clients (overrides chain/rpcUrl/account-derived clients).
  publicClient?: PublicClient;
  walletClient?: WalletClient;
};

export class ArcKit {
  readonly publicClient: PublicClient;
  readonly walletClient?: WalletClient;
  readonly account?: Account;
  readonly addresses: ContractAddresses;

  readonly commerce: CommerceClient;
  readonly identity: IdentityClient;
  readonly reputation: ReputationClient;
  readonly validation: ValidationClient;
  readonly usdc: UsdcClient;

  constructor(config: ArcKitConfig = {}) {
    const network = config.network ?? 'testnet';
    const chain = config.chain ?? arcTestnet;
    const transport: Transport = http(config.rpcUrl ?? chain.rpcUrls.default.http[0]);

    this.publicClient =
      config.publicClient ?? (createPublicClient({ chain, transport }) as PublicClient);

    this.account = config.account;
    if (config.walletClient) {
      this.walletClient = config.walletClient;
    } else if (config.account) {
      this.walletClient = createWalletClient({
        chain,
        transport,
        account: config.account,
      }) as WalletClient;
    }

    this.addresses = { ...ADDRESSES[network], ...config.contracts };

    const sub = {
      publicClient: this.publicClient,
      walletClient: this.walletClient,
      account: this.account,
    };

    this.commerce = new CommerceClient({
      ...sub,
      agenticCommerce: this.addresses.agenticCommerce as Address,
      usdc: this.addresses.usdc as Address,
    });
    this.identity = new IdentityClient({
      ...sub,
      identityRegistry: this.addresses.identityRegistry as Address,
    });
    this.reputation = new ReputationClient({
      ...sub,
      reputationRegistry: this.addresses.reputationRegistry as Address,
    });
    this.validation = new ValidationClient({
      ...sub,
      validationRegistry: this.addresses.validationRegistry as Address,
    });
    this.usdc = new UsdcClient({
      ...sub,
      usdc: this.addresses.usdc as Address,
    });
  }
}
