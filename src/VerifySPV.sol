// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVerifySPV} from "./interfaces/IVerifySPV.sol";
import {BlockHeader, SPVLib} from "./libraries/SPVLib.sol";
import {Utils} from "./Utils.sol";

struct BlockRecord {
    BlockHeader header;
    uint256 confidence;
    uint256 height;
}

contract VerifySPV is IVerifySPV{
    using SPVLib for BlockHeader;
    using Utils for bytes;

    mapping(bytes32 => BlockRecord) public blockHeaders;
    // reverse mapping for block number to block hashes
    mapping(uint256 => bytes32) public blockHashes;
    // every difficulty epoch's block hash
    // updates for every 2016th block = every 28 epochs
    bytes32 public LDEBlockHash;

    bytes32 public LatestBlockHash;

    uint256 public minimumConfidence;

    bool public isTestnet;

    event BlockRegistered(bytes32 blockHash);

    constructor(
        BlockHeader memory genesisHeader,
        uint256 height,
        uint256 _minimumConfidence,
        bool _isTestnet
    ) {
        require(
            height % 2016 == 0,
            "VerifySPV: genesis block should be at the start of a difficulty epoch"
        );
        LDEBlockHash = genesisHeader.calculateBlockHash();
        LatestBlockHash = LDEBlockHash;
        blockHeaders[LDEBlockHash] = BlockRecord({
            header: genesisHeader,
            confidence: 0,
            height: height
        });
        blockHashes[height] = LDEBlockHash;
        minimumConfidence = _minimumConfidence;
        isTestnet = _isTestnet;
    }

    function registerLatestBlock(
        BlockHeader[] calldata newEpoch,
        uint256 blockIndex
    ) public {
        require(
            blockIndex < newEpoch.length && blockIndex > 0,
            "VerifySPV: invalid block index"
        );
        require(
            newEpoch.length >= blockIndex + minimumConfidence + 1,
            "VerifySPV: invalid epoch, should contain the current block and atleast next block"
        );

        require(
            newEpoch.length <= 2016 + minimumConfidence + 1,
            "VerifySPV: invalid epoch, should not contain more than 2016 blocks"
        );

        require(
            newEpoch[0].calculateBlockHash() == LatestBlockHash,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        uint256 newHeight = blockHeaders[LatestBlockHash].height + blockIndex;

        require(
            newHeight % 2016 == 0 ||
                (newHeight % 2016 != 0 &&
                    blockHashes[(newHeight / 2016) * 2016] == LDEBlockHash),
            "VerifySPV: invalid epoch, should contain last difficulty epoch block"
        );

        require(
            blockHashes[newHeight] == bytes32(0x0),
            "VerifySPV: block already registered"
        );

        verifySequence(newEpoch, newHeight, blockIndex);

        bytes32 newEpochBlockHash = newEpoch[blockIndex].calculateBlockHash();
        blockHeaders[newEpochBlockHash] = BlockRecord({
            header: newEpoch[blockIndex],
            confidence: newEpoch.length - blockIndex - 1,
            height: newHeight
        });

        LatestBlockHash = newEpochBlockHash;

        if (newHeight % 2016 == 0) {
            LDEBlockHash = newEpochBlockHash;
        }

        blockHashes[newHeight] = newEpochBlockHash;

        emit BlockRegistered(newEpochBlockHash);
    }

    function verifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32 txHash,
        bytes32[] memory proof
    ) public view returns (bool) {
        require(
            blockIndex < blockSequence.length,
            "VerifySPV: invalid block index"
        );

        require(
            blockHeaders[blockSequence[0].calculateBlockHash()].height != 0,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        require(
            blockHeaders[
                blockSequence[blockSequence.length - 1].calculateBlockHash()
            ].height != 0,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        verifySequence(
            blockSequence,
            blockHeaders[blockSequence[0].calculateBlockHash()].height +
                blockIndex,
            blockIndex
        );

        return blockSequence[blockIndex].verifyProof(txHash, txIndex, proof);
    }

    function confidenceByHash(bytes32 blockHash) public view returns (uint256) {
        return
            blockHeaders[LatestBlockHash].confidence +
            (blockHeaders[blockHash].height -
                blockHeaders[LatestBlockHash].height);
    }

    function confidenceByHeight(uint256 height) public view returns (uint256) {
        return confidenceByHash(blockHashes[height]);
    }

    function verifySequence(
        BlockHeader[] calldata blockSequence,
        uint256 height,
        uint256 blockIndex
    ) internal view {
        if (isTestnet) {
            require(
                verifySubSequence(blockSequence, 1),
                "VerifySPV: sequence verification failed"
            );
        }

        uint256 epochDivider = blockSequence.length;
        if (height % 2016 == 0) {
            epochDivider = blockIndex;
        } else {
            uint256 overFlow = (height % 2016) +
                (blockSequence.length - blockIndex) -
                1;
            if (overFlow > 2015) {
                epochDivider -= (overFlow - 2015);
            }
        }

        uint256 target = (
            abi.encodePacked((blockHeaders[LDEBlockHash].header.nBits))
        ).convertnBitsToTarget();

        require(verifySubSequence(blockSequence[:epochDivider], target));
        if (epochDivider < blockSequence.length) {
            uint256 adjustedTarget = blockSequence[epochDivider]
                .calculateNewTarget(
                    target,
                    blockHeaders[LDEBlockHash].header.timestamp
                );
            uint256 newTarget = (
                abi.encodePacked((blockSequence[epochDivider].nBits))
            ).convertnBitsToTarget();
            require(
                SPVLib.verifyDifficultyEpochTarget(adjustedTarget, newTarget),
                "VerifySPV: adjusted difficulty is not in allowed range"
            );
            require(
                blockSequence[epochDivider - 1].calculateBlockHash() ==
                    blockSequence[epochDivider].previousBlockHash &&
                    blockSequence[epochDivider].verifyWork(),
                "VerifySPV: difficulty epoch validation failed"
            );
            require(
                verifySubSequence(blockSequence[epochDivider:], newTarget),
                "VerifySPV: post subsequence in difficulty epoch failed"
            );
        }
    }

    function verifySubSequence(
        BlockHeader[] calldata blockSequence,
        uint256 target
    ) internal view returns (bool) {
        for (uint256 i = 1; i < blockSequence.length; i++) {
            if (
                !(blockSequence[i - 1].calculateBlockHash() ==
                    blockSequence[i].previousBlockHash)
            ) {
                return false;
            }

            if (isTestnet) {
                return true;
            }
            if (
                !blockSequence[i].verifyTarget(target) &&
                blockSequence[i].verifyWork()
            ) {
                return false;
            }
        }

        return true;
    }
}
