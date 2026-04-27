REPUTATION_REGISTRY_ABI = [
    {
        "type": "function",
        "name": "giveFeedback",
        "stateMutability": "nonpayable",
        "inputs": [
            {"name": "agentId", "type": "uint256"},
            {"name": "score", "type": "int128"},
            {"name": "feedbackType", "type": "uint8"},
            {"name": "tag", "type": "string"},
            {"name": "metadataURI", "type": "string"},
            {"name": "evidenceURI", "type": "string"},
            {"name": "comment", "type": "string"},
            {"name": "feedbackHash", "type": "bytes32"},
        ],
        "outputs": [],
    },
    {
        "type": "event",
        "name": "FeedbackGiven",
        "inputs": [
            {"name": "agentId", "type": "uint256", "indexed": True},
            {"name": "from", "type": "address", "indexed": True},
            {"name": "score", "type": "int128", "indexed": False},
            {"name": "feedbackType", "type": "uint8", "indexed": False},
            {"name": "feedbackHash", "type": "bytes32", "indexed": False},
        ],
        "anonymous": False,
    },
]
