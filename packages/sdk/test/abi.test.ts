import { describe, expect, it } from 'vitest';
import {
  agenticCommerceAbi,
  erc20Abi,
  identityRegistryAbi,
  reputationRegistryAbi,
  validationRegistryAbi,
} from '../src/abi/index.js';

describe('ABI exports', () => {
  it('agenticCommerceAbi includes all ERC-8183 functions', () => {
    const names = agenticCommerceAbi.filter((x) => x.type === 'function').map((x) => x.name);
    expect(names).toContain('createJob');
    expect(names).toContain('setBudget');
    expect(names).toContain('fund');
    expect(names).toContain('submit');
    expect(names).toContain('complete');
    expect(names).toContain('reject');
    expect(names).toContain('claimRefund');
    expect(names).toContain('getJob');
  });

  it('agenticCommerceAbi includes JobCreated event', () => {
    const events = agenticCommerceAbi.filter((x) => x.type === 'event').map((x) => x.name);
    expect(events).toContain('JobCreated');
  });

  it('identityRegistryAbi includes register and ownerOf', () => {
    const names = identityRegistryAbi.filter((x) => x.type === 'function').map((x) => x.name);
    expect(names).toContain('register');
    expect(names).toContain('ownerOf');
    expect(names).toContain('tokenURI');
    expect(names).toContain('balanceOf');
  });

  it('reputationRegistryAbi includes giveFeedback', () => {
    const names = reputationRegistryAbi.filter((x) => x.type === 'function').map((x) => x.name);
    expect(names).toContain('giveFeedback');
  });

  it('validationRegistryAbi includes request, response, and status', () => {
    const names = validationRegistryAbi.filter((x) => x.type === 'function').map((x) => x.name);
    expect(names).toContain('validationRequest');
    expect(names).toContain('validationResponse');
    expect(names).toContain('getValidationStatus');
  });

  it('erc20Abi includes balanceOf, allowance, approve, transfer', () => {
    const names = erc20Abi.filter((x) => x.type === 'function').map((x) => x.name);
    expect(names).toContain('balanceOf');
    expect(names).toContain('allowance');
    expect(names).toContain('approve');
    expect(names).toContain('transfer');
  });
});
