import { type Hash, type PublicClient, decodeEventLog, keccak256, toHex } from 'viem';
import { USDC_DECIMALS } from './constants.js';
import { TransactionRevertedError, TransactionTimeoutError } from './errors.js';

/// Convert a USDC amount (as number, e.g. 1.5 for 1.5 USDC) to base units (6 decimals).
export function toUsdcBase(amount: number | bigint): bigint {
  if (typeof amount === 'bigint') return amount;
  return BigInt(Math.round(amount * 10 ** USDC_DECIMALS));
}

/// Convert USDC base units to a human-readable number.
export function fromUsdcBase(amount: bigint): number {
  return Number(amount) / 10 ** USDC_DECIMALS;
}

/// Hash a UTF-8 string with keccak256.
export function hashString(s: string): `0x${string}` {
  return keccak256(toHex(s));
}

/// Wait for a transaction receipt and throw a typed error on revert/timeout.
export async function waitForReceipt(publicClient: PublicClient, hash: Hash, timeoutMs = 120_000) {
  try {
    const receipt = await publicClient.waitForTransactionReceipt({ hash, timeout: timeoutMs });
    if (receipt.status !== 'success') {
      throw new TransactionRevertedError(hash);
    }
    return receipt;
  } catch (err) {
    if (err instanceof Error && err.name === 'WaitForTransactionReceiptTimeoutError') {
      throw new TransactionTimeoutError(hash, timeoutMs);
    }
    throw err;
  }
}

/// Find the first event matching the given ABI in a receipt's logs and decode its args.
/// Returns undefined if no matching event is found.
export function findEvent<TArgs extends Record<string, unknown>>(
  logs: Array<{ topics: readonly `0x${string}`[]; data: `0x${string}`; address: `0x${string}` }>,
  abi: readonly unknown[],
  eventName: string,
): TArgs | undefined {
  for (const log of logs) {
    try {
      const decoded = decodeEventLog({
        abi: abi as never,
        eventName: eventName as never,
        topics: log.topics as [signature: `0x${string}`, ...args: `0x${string}`[]],
        data: log.data,
      });
      return decoded.args as unknown as TArgs;
    } catch {}
  }
  return undefined;
}
