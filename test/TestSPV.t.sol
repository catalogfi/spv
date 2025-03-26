// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BlockHeader, LibBitcoin} from "../src/libraries/LibBitcoin.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import {Test} from "forge-std/Test.sol";

contract TestSPV is Test {
    function test_bytesToUint256conversion() public pure {
        bytes memory data = hex"000000000000000000000000000000000000000000000000ffffffffffffffff";
        uint256 result = LibBitcoin.bytesToUint256(data);
        assert(result == 18446744073709551615);
    }

    // big endian 
    // "version": "0x20000000",
    // "previousblockhash": "0x253BDF37697BE864B057535D11CE4F6D95E16950C3DC8B973FA1CFF510DFEE03",
    // "merkleroot": "0xF69056B2DF506BFB58B61DB5D2847D4F560D5DFC2D30F9FD47EA82A92E7D7FA9",
    // "time": "0x67ddb48c",
    // "bits": "0x207fffff",
    // "nonce": "0x00000000"

    // "version": "0x20000000",
    // "previousblockhash": "0x253bdf37697be864b057535d11ce4f6d95e16950c3dc8b973fa1cff510dfee03",
    // "merkleroot": "0xf69056b2df506bfb58b61db5d2847d4f560d5dfc2d30f9fd47ea82a92e7d7fa9",
    // "time": "0x67ddb48c",
    // "bits": "0xffff7f20",
    // "nonce": "0x00000000"

    // bytes4 version = 0x00000002;
    // bytes32 previousBlockHash = 0x253bdf37697be864b057535d11ce4f6d95e16950c3dc8b973fa1cff510dfee03;
    // bytes32 merkleRootHash = 0xf69056b2df506bfb58b61db5d2847d4f560d5dfc2d30f9fd47ea82a92e7d7fa9;
    // bytes4 timestamp = 0x8cb4dd67;
    // bytes4 nBits = 0xffff7f20;
    // bytes4 nonce = 0x00000000;

    // bytes4 version= 0x00000020;
    // bytes4 timestamp= 0x8cb4dd67;
    // bytes4 nBits= 0xffff7f20;
    // bytes4 nonce= 0x00000000;
    // bytes32 previousBlockHash = 0x253bdf37697be864b057535d11ce4f6d95e16950c3dc8b973fa1cff510dfee03;
    // bytes32 merkleRootHash= 0xf69056b2df506bfb58b61db5d2847d4f560d5dfc2d30f9fd47ea82a92e7d7fa9;

    bytes4 version= 0x00000020;
    bytes32 previousBlockHash= 0x2a092907bb064cd4607ca0b5468e6d78494ab261bc839730d0d5f19b1a8eab18;
    bytes32 merkleRootHash= 0xca495e5c787a3464b3b1f2f38f2d517a94f2f4c2238801eec8acef2871d612e7;
    bytes4 timestamp= 0x38c2dd67;
    bytes4 nBits= 0xffff7f20;
    bytes4 nonce= 0x01000000;

    BlockHeader header = BlockHeader(version, previousBlockHash, merkleRootHash, timestamp, nBits, nonce);

    function test_calculateBlockHash() public view {
        bytes32 result = LibSPV.calculateBlockHash(header);
        assert(result == 0x09a6267d97f3d398db4f5558deb573ddf04016d1728b149b2463a5672a8ad2cf);
    }

    // bytes32[] public proof = new bytes32[](2);
    // // proof.push(0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38);
    // proof[0] = 0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38;

    // proof.push(0xbee705c560dad3adc2482075c076fc05d04c64ab0f27632ce827d7706c53d1cb);

    function test_proof() public view {
        bytes32[] memory proof = new bytes32[](1);

        // proof[0] = 0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38;
        proof[0] = 0xbee705c560dad3adc2482075c076fc05d04c64ab0f27632ce827d7706c53d1cb;

        LibSPV.verifyProof(header, 0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38, 0, proof);
    }    
}
