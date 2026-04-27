import { describe, expect, it } from 'vitest';
import { fromUsdcBase, hashString, toUsdcBase } from '../src/utils.js';

describe('toUsdcBase', () => {
  it('converts a number to 6-decimal base units', () => {
    expect(toUsdcBase(1)).toBe(1_000_000n);
    expect(toUsdcBase(1.5)).toBe(1_500_000n);
    expect(toUsdcBase(0.000001)).toBe(1n);
  });

  it('passes a bigint through unchanged', () => {
    expect(toUsdcBase(2_500_000n)).toBe(2_500_000n);
  });

  it('rounds floating-point input to nearest base unit', () => {
    expect(toUsdcBase(0.1 + 0.2)).toBe(300_000n);
  });
});

describe('fromUsdcBase', () => {
  it('converts base units back to USDC', () => {
    expect(fromUsdcBase(1_000_000n)).toBe(1);
    expect(fromUsdcBase(2_500_000n)).toBe(2.5);
    expect(fromUsdcBase(0n)).toBe(0);
  });
});

describe('hashString', () => {
  it('produces a deterministic 32-byte keccak256 hex string', () => {
    const h1 = hashString('hello world');
    const h2 = hashString('hello world');
    expect(h1).toBe(h2);
    expect(h1).toMatch(/^0x[0-9a-f]{64}$/);
  });

  it('produces different hashes for different inputs', () => {
    expect(hashString('a')).not.toBe(hashString('b'));
  });
});
