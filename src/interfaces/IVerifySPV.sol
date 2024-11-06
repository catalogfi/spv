// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {BlockHeader} from "../libraries/LibSPV.sol";

interface IVerifySPV {
    function registerLatestBlock(
        BlockHeader[] calldata newEpoch,
        uint256 blockIndex
    ) external;

    function verifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32 txHash,
        bytes32[] memory proof
    ) external view returns (bool);
}
