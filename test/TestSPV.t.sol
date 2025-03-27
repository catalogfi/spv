// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BlockHeader, LibBitcoin} from "../src/libraries/LibBitcoin.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import {Test,console} from "forge-std/Test.sol";
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

    bytes4 version = 0x00000020;
    bytes32 previousBlockHash = 0x2a092907bb064cd4607ca0b5468e6d78494ab261bc839730d0d5f19b1a8eab18;
    bytes32 merkleRootHash = 0xca495e5c787a3464b3b1f2f38f2d517a94f2f4c2238801eec8acef2871d612e7;
    bytes4 timestamp = 0x38c2dd67;
    bytes4 nBits = 0xffff7f20;
    bytes4 nonce = 0x01000000;

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

    function test_proofRecreate() public pure {
        bytes32 x = 0x86560b23cf85525bb9f9a890e0d4bb809f564e5e623bbf621ccd6246e1953e55;
        bytes32 y = 0x244fd62704eb0158eb3696fa2f72c25674d51ef465acdee137cbdb69ce1b7891;

        bytes32 result = LibSPV.concatHash(x, y);
        assert(result == 0x3158ff37b752dc51926e36aef0261a9a3cc7b95e69fdbd2576f9566ecc7947ec);
    }

    // [
    //   "0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b",
    //   "0xc308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e",
    //   "0x12ebcdd62faeb8be30f27a8ac457a23ba37f641f4fd25a1e6e2460f90e29e268",
    //   "0x953f0da2eeb2cb0d6cd48c7ed9f216d5c4367091af6cd5d0ac5832da366e6d3d",
    //   "0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d",
    //   "0x4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a",
    //   "0xb65c6dd561d116a781e2fb90f4df8c2cd8e848f6da252f50723e9f0f4c2820a1",
    //   "0x7c123bf23acddce83c2913daaa1550b7d57da32a8f98646ce2b8f336f3dfdfcc",
    //   "0x43de34ee45c030f05450cee186cf7f658618b271c4a6b31e334655417cfec548",
    //   "0x03c913821cf8ad218d6dc6ddf8c3c576f191e5644da839afe78522e749d0cb13",
    //   "0x4f66cdf0990dc14e43e0029162848f4316c2ee43784415f0a18a0fc64893636c"
    // ]
    // function test_bigHash() public {
    //     Merkle m = new Merkle();

    //     bytes32[] memory leaves = new bytes32[](11);

    //     leaves[0] = 0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b;
    //     leaves[1] = 0xc308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e;
    //     leaves[2] = 0x12ebcdd62faeb8be30f27a8ac457a23ba37f641f4fd25a1e6e2460f90e29e268;
    //     leaves[3] = 0x953f0da2eeb2cb0d6cd48c7ed9f216d5c4367091af6cd5d0ac5832da366e6d3d;
    //     leaves[4] = 0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d;
    //     leaves[5] = 0x4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a;
    //     leaves[6] = 0xb65c6dd561d116a781e2fb90f4df8c2cd8e848f6da252f50723e9f0f4c2820a1;
    //     leaves[7] = 0x7c123bf23acddce83c2913daaa1550b7d57da32a8f98646ce2b8f336f3dfdfcc;
    //     leaves[8] = 0x43de34ee45c030f05450cee186cf7f658618b271c4a6b31e334655417cfec548;
    //     leaves[9] = 0x03c913821cf8ad218d6dc6ddf8c3c576f191e5644da839afe78522e749d0cb13;
    //     leaves[10] = 0x4f66cdf0990dc14e43e0029162848f4316c2ee43784415f0a18a0fc64893636c;

    //     bytes32 root = m.getRoot(leaves);
    //     console.logBytes32(root);
    // }
}
