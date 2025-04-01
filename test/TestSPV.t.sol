// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BlockHeader, LibBitcoin} from "../src/libraries/LibBitcoin.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import {Test, console} from "forge-std/Test.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol";

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

    bytes4 version = 0x00000030;
    bytes32 previousBlockHash = 0x49c7cac87d50decadf329a9df4eb9903bba4fee2dc42e2ee135bc5197c855b02;
    bytes32 merkleRootHash = 0x41a461dfcc02efcd39625f081fd24e951d3d181f3f5a1777a74d9cfd8d12570e;
    bytes4 timestamp = 0x8c15e567;
    bytes4 nBits = 0xffff7f20;
    bytes4 nonce = 0x02000000;

    BlockHeader header = BlockHeader(version, previousBlockHash, merkleRootHash, timestamp, nBits, nonce);

    function test_calculateBlockHash() public view {
        bytes32 result = LibSPV.calculateBlockHash(header);
        // assert(result == 0x09a6267d97f3d398db4f5558deb573ddf04016d1728b149b2463a5672a8ad2cf);
    }

    // bytes32[] public proof = new bytes32[](2);
    // // proof.push(0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38);
    // proof[0] = 0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38;

    // proof.push(0xbee705c560dad3adc2482075c076fc05d04c64ab0f27632ce827d7706c53d1cb);

    function test_proof() public view {
        bytes32[] memory proof = new bytes32[](5);

        // proof[0] = 0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d;
        // proof[1] = 0x056c7c24fa1354e5a48d451154e22e420aa542867abeaa6b203ece181ccdac52;
        // proof[2] = 0x1ea1d5edcd7e776e16a6e0c523a8be8f5635592e7e4d3cb1a94d04acebe23912;
        // proof[3] = 0xa28c327dede8b27e1e4cc3e0d373bc91361bb7f4370aea686b70d22e9c3605fb;
        proof[0] = 0x3c0b0b0c36c9633e098d77703dc80101295ea6ca136b2125b1b2862e63f426fd;
        proof[1] = 0x80d2c687fdc49c573f948718b7c92285198b0eae8ccf601ac20fd84d6657fea9;
        proof[2] = 0xf49e4cbf319e8f5a9df2bca0eceb94904c352a0f7f9c7d35a74aa9ae11c97af6;
        proof[3] = 0xc4c15d54f823ffb4684e40d03ae917b57e6ec433982cbd12780dcc5e9b1ddf96;
        proof[4] = 0xb23d9b2085f89659482050ba1d2c488c9adfb9ea96bf2d788078c65813b2579a;

        // LibSPV.verifyProof(header, 0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b, 0, proof);
        bool returnVal =
            LibSPV.verifyProof(header, 0x442277db570ed285d190b7104e7610526ea44dcee34318eae35eeee97d6dfad1, 7, proof);
        assert(returnVal == true);
    }

    // function test_proofRecreate() public pure {
    //     bytes32 x = 0x86560b23cf85525bb9f9a890e0d4bb809f564e5e623bbf621ccd6246e1953e55;
    //     bytes32 y = 0x244fd62704eb0158eb3696fa2f72c25674d51ef465acdee137cbdb69ce1b7891;

    //     bytes32 result = LibSPV.concatHash(x, y);
    //     assert(result == 0x3158ff37b752dc51926e36aef0261a9a3cc7b95e69fdbd2576f9566ecc7947ec);
    // }
}
