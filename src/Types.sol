// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct BlockHeader {
    bytes32 merkleRootHash;
    bytes4 nBits;
    bytes4 nonce;
    bytes32 previousBlockHash;
    bytes4 timestamp;
    bytes4 version;
}

struct Outpoint {
    bytes spk;
    uint32 amount;
}

struct Prevout {
    bytes32 txid;
    uint32 vout;
}
