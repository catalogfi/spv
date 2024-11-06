// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {LibBitcoin, BlockHeader} from "./LibBitcoin.sol";

library SPVLib {
    using Math for uint256;
    using LibBitcoin for bytes;

    uint256 internal constant DIFFICULTY_EPOCH_PERIOD = 2 * 7 * 24 * 60 * 60; // 2 weeks in seconds
    uint256 internal constant DIFFICULTY_EPOCH_PERIOD_DIV_4 =
        DIFFICULTY_EPOCH_PERIOD / 4; // DIFFICULTY_EPOCH_PERIOD divided by 4
    uint256 internal constant DIFFICULTY_EPOCH_PERIOD_MUL_4 =
        DIFFICULTY_EPOCH_PERIOD * 4; // DIFFICULTY_EPOCH_PERIOD multiplied by 4
    uint256 internal constant DIFFICULTY_EPOCH_PERIOD_BLOCKS = 2016; // 2 weeks in blocks

    function calculateBlockHash(
        BlockHeader memory header
    ) internal pure returns (bytes32) {
        bytes memory headerData = abi.encodePacked(
            header.version,
            header.previousBlockHash,
            header.merkleRootHash,
            header.timestamp,
            header.nBits,
            header.nonce
        );

        // Perform double SHA-256 hashing
        return (headerData).doubleHash();
    }

    function verifyProof(
        BlockHeader memory header,
        bytes32 txHash,
        uint256 txIndex,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 result = abi
            .encodePacked(txHash)
            .convertToBigEndian()
            .convertToBytes32();

        for (uint256 i = 0; i < proof.length; i++) {
            if (txIndex % 2 == 1) {
                result = concatHash(proof[i], result);
            } else {
                result = concatHash(result, proof[i]);
            }
            txIndex /= 2;
        }

        return header.merkleRootHash == result;
    }

    // for modularity we expect the caller to handle the case in testnet4 if the difficulty is 1
    function verifyWork(
        BlockHeader calldata header
    ) internal pure returns (bool) {
        return
            (
                (abi.encodePacked(calculateBlockHash(header)))
                    .convertToBigEndian()
            ).bytesToUint256() <
            (abi.encodePacked(header.nBits)).convertnBitsToTarget();
    }

    function verifyTarget(
        BlockHeader calldata header,
        uint256 target
    ) internal pure returns (bool) {
        return
            (abi.encodePacked(header.nBits)).convertnBitsToTarget() == target;
    }

    function verifyDifficultyEpochTarget(
        uint256 newTarget,
        uint256 target
    ) internal pure returns (bool) {
        if (newTarget >= target) {
            return (newTarget - target) * 100 <= target;
        } else {
            return (target - newTarget) * 100 <= target;
        }
    }

    function calculateNewTarget(
        BlockHeader calldata header,
        uint256 LDEtarget,
        bytes4 LDETimestamp
    ) internal pure returns (uint256 target) {
        uint256 _elapsedTime;
        (, _elapsedTime) = (
            abi
                .encodePacked(header.timestamp)
                .convertToBigEndian()
                .bytesToUint256()
        ).trySub(
                abi
                    .encodePacked(LDETimestamp)
                    .convertToBigEndian()
                    .bytesToUint256()
            );

        if (_elapsedTime < DIFFICULTY_EPOCH_PERIOD_DIV_4) {
            _elapsedTime = DIFFICULTY_EPOCH_PERIOD_DIV_4;
        }
        if (_elapsedTime > DIFFICULTY_EPOCH_PERIOD_MUL_4) {
            _elapsedTime = DIFFICULTY_EPOCH_PERIOD_MUL_4;
        }

        uint256 _adjusted;
        (, _adjusted) = LDEtarget.tryDiv(65536);
        (, _adjusted) = _adjusted.tryMul(_elapsedTime);
        (, _adjusted) = _adjusted.tryDiv(DIFFICULTY_EPOCH_PERIOD);
        (, _adjusted) = _adjusted.tryMul(65536);
        return _adjusted;
    }

    function concatHash(
        bytes32 left,
        bytes32 right
    ) internal pure returns (bytes32) {
        return abi.encodePacked(left, right).doubleHash();
    }
}
