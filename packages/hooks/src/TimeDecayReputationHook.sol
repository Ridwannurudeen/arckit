// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseHook} from "./BaseHook.sol";
import {IAgenticCommerce} from "./interfaces/IAgenticCommerce.sol";

/// @title TimeDecayReputationHook
/// @notice ERC-8183 hook that records on-chain reputation events for providers
///         on every successful job completion, with a half-life decay model
///         exposed via view functions.
///
/// @dev    Reputation here is a hook-local score, not the canonical
///         ReputationRegistry (ERC-8004). Off-chain consumers should combine
///         the two: ERC-8004 for permanent feedback records, and this hook for
///         freshness/recency-weighted scoring tied specifically to ERC-8183 jobs.
contract TimeDecayReputationHook is BaseHook {
    struct Record {
        uint64 timestamp;
        int128 score; // signed; negative scores allowed for rejected jobs
    }

    /// @notice Default score awarded on complete(). Configurable per provider.
    int128 public constant DEFAULT_COMPLETE_SCORE = 100;
    /// @notice Default score on reject().
    int128 public constant DEFAULT_REJECT_SCORE = -50;

    mapping(address provider => Record[]) private _records;

    event ScoreRecorded(address indexed provider, uint256 indexed jobId, int128 score, uint64 timestamp);

    constructor(address _agenticCommerce) BaseHook(_agenticCommerce) {}

    /// @notice Returns all recorded events for a provider.
    function getRecords(address provider) external view returns (Record[] memory) {
        return _records[provider];
    }

    /// @notice Returns the number of recorded events for a provider.
    function recordCount(address provider) external view returns (uint256) {
        return _records[provider].length;
    }

    /// @notice Returns a half-life decayed score for a provider.
    /// @param  provider The provider address.
    /// @param  halflifeSeconds The decay half-life in seconds (e.g. 30 days = 2_592_000).
    /// @return decayed The cumulative score with each record decayed by 0.5^(age/halflife).
    /// @dev    Uses integer approximation via right-shift per halflife elapsed; sufficient
    ///         for monotonic ranking but not financial accounting.
    function decayedScore(address provider, uint64 halflifeSeconds) external view returns (int256 decayed) {
        if (halflifeSeconds == 0) halflifeSeconds = 1;
        Record[] memory records = _records[provider];
        uint64 nowTs = uint64(block.timestamp);
        for (uint256 i = 0; i < records.length; i++) {
            uint64 age = nowTs - records[i].timestamp;
            uint64 halvings = age / halflifeSeconds;
            if (halvings >= 64) continue; // fully decayed
            int256 contribution = int256(records[i].score) >> uint256(halvings);
            decayed += contribution;
        }
    }

    /// @inheritdoc BaseHook
    function beforeAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }

    /// @inheritdoc BaseHook
    function afterAction(uint256 jobId, bytes4 selector, bytes calldata) external override onlyAgenticCommerce {
        if (selector == SELECTOR_COMPLETE) {
            address provider = agenticCommerce.getJob(jobId).provider;
            _record(provider, jobId, DEFAULT_COMPLETE_SCORE);
        } else if (selector == SELECTOR_REJECT) {
            address provider = agenticCommerce.getJob(jobId).provider;
            _record(provider, jobId, DEFAULT_REJECT_SCORE);
        }
    }

    function _record(address provider, uint256 jobId, int128 score) internal {
        _records[provider].push(Record({timestamp: uint64(block.timestamp), score: score}));
        emit ScoreRecorded(provider, jobId, score, uint64(block.timestamp));
    }
}
