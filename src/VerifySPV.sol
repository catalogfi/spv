// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVerifySPV} from "./interfaces/IVerifySPV.sol";
import {BlockHeader, SPVLib} from "./libraries/SPVLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Utils} from "./Utils.sol";

contract VerifySPV is IVerifySPV {
    using SPVLib for BlockHeader;
    using Utils for bytes;

    mapping(bytes32 => BlockHeader) public blockHeaders;
    // every difficulty epoch's block hash
    // updates for every 2016th block = every 28 epochs
    bytes32 public LDEBlockHash;
    // epoch is incremented for every block register ,1 epoch = 72 blocks
    uint256 public epoch;
    bool isMainnet;

    event BlockRegistered(bytes32 blockHash);

    constructor(BlockHeader memory genesisHeader, bool _isMainnet) {
        LDEBlockHash = genesisHeader.calculateBlockHash();
        isMainnet = _isMainnet;
        blockHeaders[genesisHeader.calculateBlockHash()] = genesisHeader;
        epoch = 0;
    }

    function registerBlock(BlockHeader[] calldata newEpoch) public {
        require(newEpoch.length == 76, "VerifySPV: invalid epoch, should contain previous 72 blocks and next 3 blocks");

        require(
            blockHeaders[newEpoch[0].calculateBlockHash()].previousBlockHash != bytes32(0x0),
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        epoch++;

        verifySequence(newEpoch);

        bytes32 newEpochBlockHash = newEpoch[72].calculateBlockHash();
        blockHeaders[newEpochBlockHash] = newEpoch[72];

        emit BlockRegistered(newEpochBlockHash);
    }

    function verifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32 txHash,
        bytes32[] memory proof
    ) public view returns (bool) {
        require(blockSequence.length == 73, "VerifySPV: inclusion verification needs all 72 blocks in the epoch");

        require(
            blockHeaders[blockSequence[0].calculateBlockHash()].previousBlockHash != bytes32(0x0),
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        require(
            blockHeaders[blockSequence[72].calculateBlockHash()].previousBlockHash != bytes32(0x0),
            "VerifySPV: invalid epoch, ending block not on chain"
        );
        uint256 target = (abi.encodePacked((blockSequence[0].nBits))).convertnBitsToTarget();
        verifySubSequence(blockSequence[0:72], target);
        return blockSequence[blockIndex].verifyProof(txHash, txIndex, proof);
    }

    function verifySequence(BlockHeader[] calldata blockSequence) internal {
        uint256 target = (abi.encodePacked((blockHeaders[LDEBlockHash].nBits))).convertnBitsToTarget();
        if (epoch % 28 == 0) {
            require(
                verifySubSequence(blockSequence[:72], target), "VerifySPV: pre subsequence in difficulty epoch failed"
            );
            uint256 adjustedTarget = blockSequence[72].calculateNewTarget(target, blockHeaders[LDEBlockHash].timestamp);
            uint256 newTarget = (abi.encodePacked((blockSequence[72].nBits))).convertnBitsToTarget();
            require(
                SPVLib.verifyDifficultyEpochTarget(adjustedTarget, newTarget),
                "VerifySPV: adjusted difficulty is not in allowed range"
            );
            require(
                blockSequence[71].calculateBlockHash() == blockSequence[72].previousBlockHash,
                "VerifySPV: difficulty epoch validation failed"
            );
            if(isMainnet) {
                require(blockSequence[72].verifyWork(), "VerifySPV: difficulty epoch validation failed");
            }

            require(
                verifySubSequence(blockSequence[73:], newTarget),
                "VerifySPV: post subsequence in difficulty epoch failed"
            );
            LDEBlockHash = blockSequence[72].calculateBlockHash();
        } else {
            require(verifySubSequence(blockSequence, target), "VerifySPV: sequence verification failed");
        }
    }

    function verifySubSequence(BlockHeader[] calldata blockSequence, uint256 target) internal view returns (bool) {
        for (uint256 i = 1; i < blockSequence.length; i++) {
            if (
                !(
                    blockSequence[i - 1].calculateBlockHash() == blockSequence[i].previousBlockHash
                )
            ) return false;
            else {
                if(isMainnet) continue;
                if (!(blockSequence[i].verifyTarget(target) && blockSequence[i].verifyWork())) return false;
            }
        }

        return true;
    }
}
