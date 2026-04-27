import { privateKeyToAccount } from 'viem/accounts';
import { describe, expect, it } from 'vitest';
import { ArcKit } from '../src/client.js';
import { ADDRESSES, arcTestnet } from '../src/constants.js';
import { WalletRequiredError } from '../src/errors.js';

const TEST_PK = '0x0000000000000000000000000000000000000000000000000000000000000001' as const;

describe('ArcKit construction', () => {
  it('initializes in read-only mode without an account', () => {
    const arc = new ArcKit({ network: 'testnet' });
    expect(arc.account).toBeUndefined();
    expect(arc.walletClient).toBeUndefined();
    expect(arc.publicClient).toBeDefined();
  });

  it('initializes with an account in write-capable mode', () => {
    const account = privateKeyToAccount(TEST_PK);
    const arc = new ArcKit({ account, network: 'testnet' });
    expect(arc.account?.address).toBe(account.address);
    expect(arc.walletClient).toBeDefined();
  });

  it('uses Arc testnet addresses by default', () => {
    const arc = new ArcKit();
    expect(arc.addresses.agenticCommerce).toBe(ADDRESSES.testnet.agenticCommerce);
    expect(arc.addresses.identityRegistry).toBe(ADDRESSES.testnet.identityRegistry);
    expect(arc.addresses.reputationRegistry).toBe(ADDRESSES.testnet.reputationRegistry);
    expect(arc.addresses.validationRegistry).toBe(ADDRESSES.testnet.validationRegistry);
    expect(arc.addresses.usdc).toBe(ADDRESSES.testnet.usdc);
  });

  it('respects contract address overrides', () => {
    const arc = new ArcKit({
      contracts: { agenticCommerce: '0x000000000000000000000000000000000000dEaD' },
    });
    expect(arc.addresses.agenticCommerce).toBe('0x000000000000000000000000000000000000dEaD');
    expect(arc.addresses.identityRegistry).toBe(ADDRESSES.testnet.identityRegistry);
  });

  it('exposes all five sub-clients', () => {
    const arc = new ArcKit();
    expect(arc.commerce).toBeDefined();
    expect(arc.identity).toBeDefined();
    expect(arc.reputation).toBeDefined();
    expect(arc.validation).toBeDefined();
    expect(arc.usdc).toBeDefined();
  });

  it('uses the configured chain', () => {
    const arc = new ArcKit();
    expect(arc.publicClient.chain?.id).toBe(arcTestnet.id);
  });
});

describe('write methods without wallet', () => {
  it('commerce.createJob throws WalletRequiredError', async () => {
    const arc = new ArcKit();
    await expect(
      arc.commerce.createJob({
        provider: '0x0000000000000000000000000000000000000001',
        evaluator: '0x0000000000000000000000000000000000000002',
        expiredAt: 0n,
        description: 'test',
      }),
    ).rejects.toBeInstanceOf(WalletRequiredError);
  });

  it('identity.register throws WalletRequiredError', async () => {
    const arc = new ArcKit();
    await expect(arc.identity.register({ metadataURI: 'ipfs://x' })).rejects.toBeInstanceOf(
      WalletRequiredError,
    );
  });

  it('usdc.approve throws WalletRequiredError', async () => {
    const arc = new ArcKit();
    await expect(
      arc.usdc.approve('0x0000000000000000000000000000000000000001', 1),
    ).rejects.toBeInstanceOf(WalletRequiredError);
  });
});
