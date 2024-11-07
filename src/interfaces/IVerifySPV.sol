// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {BlockHeader} from "../libraries/LibSPV.sol";
import {Prevout, Outpoint} from "../libraries/LibBitcoin.sol";

interface IVerifySPV {
    // @dev Register a new block on the chain
    // @param newEpoch - Array of block headers for the new epoch
    // @param blockIndex - Index of the block to be registered in the new epoch
    // @notice The blockIndex should be greater than 0 and less than the length of the newEpoch array
    // @notice The newEpoch array should contain the current block and atleast minimumConfidence number of blocks
    // @notice The newEpoch array should not contain more than 2016 blocks
    // @notice The starting block of the newEpoch should be the latest block hash
    // @notice To register a new block from new difficulty epoch, the first block of the newEpoch should be registered first
    function registerLatestBlock(
        BlockHeader[] calldata newEpoch,
        uint256 blockIndex
    ) external;

    // @dev Register a block between two blocks already on the chain
    // @param blockSequence - Array of block headers for the new epoch
    // @param blockIndex - Index of the block to be registered in the new epoch
    // @notice The intended block should be between the first and last block of the blockSequence
    // @notice This can be used to optimize the gas cost of verify function if demand for number of
    // @notice tx inclusion proofs are higer between two already registered blocks which are undesirably far in height.
    function registerInclusiveBlock(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex
    ) external;

    // @dev Verify the inclusion of a transaction in a block
    // @param blockSequence - Array of block headers between two blocks already on the chain
    // @param blockIndex - Index of the desired block in the blockSequence
    // @param txIndex - Index of the transaction in the block
    // @param txHash - Transaction hash to be verified
    // @param proof - Array of merkle proof hashes
    // @return confirmations - Uint256 indicating the number of confirmations of the block 
    function verifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32 txHash,
        bytes32[] memory proof
    ) external view returns (uint256);

    // @dev Parse and verify the inclusion of a transaction in a block
    // @param blockSequence - Array of block headers between two blocks already on the chain
    // @param txHex - Transaction in raw hex bytes to be verified
    // @param blockIndex - Index of the desired block in the blockSequence
    // @param txIndex - Index of the transaction in the block
    // @param proof - Array of merkle proof hashes
    // @return confirmations - Uint256 indicating the number of confirmations of the block 
    // @return txHash - Hash of the transaction
    // @return prevOuts - Array of previous outputs of inputs in the transaction
    // @return outPoints - Array of outputs of the transaction
    function parseAndVerifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        bytes calldata txHex,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32[] memory proof
    ) external view returns (uint256, bytes32, Prevout[] memory, Outpoint[] memory);

    // @dev Get confidence of a block by its hash
    // @dev Confidence is the number of blocks after the block in the longest chain
    // @dev plus the minimum confidence used to consider the latest block as confirmed
    // @param blockHash - Hash of the block
    function confidenceByHash(bytes32 blockHash) external view returns (uint256);
}
