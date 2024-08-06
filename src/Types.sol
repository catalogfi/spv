// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

struct BlockHeader {
    bytes4 version;
    bytes4 timestamp;
    bytes4 nBits;
    bytes4 nonce;
    bytes32 previousBlockHash;
    bytes32 merkleRootHash;
}