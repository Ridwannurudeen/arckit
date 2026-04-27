export const reputationRegistryAbi = [
  {
    type: 'function',
    name: 'giveFeedback',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'agentId', type: 'uint256' },
      { name: 'score', type: 'int128' },
      { name: 'feedbackType', type: 'uint8' },
      { name: 'tag', type: 'string' },
      { name: 'metadataURI', type: 'string' },
      { name: 'evidenceURI', type: 'string' },
      { name: 'comment', type: 'string' },
      { name: 'feedbackHash', type: 'bytes32' },
    ],
    outputs: [],
  },
  {
    type: 'event',
    name: 'FeedbackGiven',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true },
      { name: 'from', type: 'address', indexed: true },
      { name: 'score', type: 'int128', indexed: false },
      { name: 'feedbackType', type: 'uint8', indexed: false },
      { name: 'feedbackHash', type: 'bytes32', indexed: false },
    ],
    anonymous: false,
  },
] as const;
