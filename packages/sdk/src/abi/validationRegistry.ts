export const validationRegistryAbi = [
  {
    type: 'function',
    name: 'validationRequest',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'validator', type: 'address' },
      { name: 'agentId', type: 'uint256' },
      { name: 'requestURI', type: 'string' },
      { name: 'requestHash', type: 'bytes32' },
    ],
    outputs: [],
  },
  {
    type: 'function',
    name: 'validationResponse',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'requestHash', type: 'bytes32' },
      { name: 'response', type: 'uint8' },
      { name: 'responseURI', type: 'string' },
      { name: 'responseHash', type: 'bytes32' },
      { name: 'tag', type: 'string' },
    ],
    outputs: [],
  },
  {
    type: 'function',
    name: 'getValidationStatus',
    stateMutability: 'view',
    inputs: [{ name: 'requestHash', type: 'bytes32' }],
    outputs: [
      { name: 'validatorAddress', type: 'address' },
      { name: 'agentId', type: 'uint256' },
      { name: 'response', type: 'uint8' },
      { name: 'responseHash', type: 'bytes32' },
      { name: 'tag', type: 'string' },
      { name: 'lastUpdate', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'ValidationRequested',
    inputs: [
      { name: 'requestHash', type: 'bytes32', indexed: true },
      { name: 'validator', type: 'address', indexed: true },
      { name: 'agentId', type: 'uint256', indexed: true },
    ],
    anonymous: false,
  },
  {
    type: 'event',
    name: 'ValidationResponded',
    inputs: [
      { name: 'requestHash', type: 'bytes32', indexed: true },
      { name: 'response', type: 'uint8', indexed: false },
    ],
    anonymous: false,
  },
] as const;
