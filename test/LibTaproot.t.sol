// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LibTaproot} from "src/libraries/LibTaproot.sol";
import {BabylonScriptUtils} from "src/babylon/Script.sol";
import {LibEllipticCurve} from "src/libraries/LibEllipticCurve.sol";
import {console} from "forge-std/console.sol";

contract TaprootIndirection is Test {
    uint256 public constant GX =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    function _serializeScript(
        bytes calldata script
    ) public pure returns (bytes memory) {
        return LibTaproot.serializeScript(script);
    }

    function serializeScript(
        bytes memory script
    ) public view returns (bytes memory) {
        return this._serializeScript(script);
    }

    function _computeMastRootFromMerkleProof(
        bytes calldata script,
        bytes32[] calldata merkleProof
    ) public pure returns (bytes32) {
        return LibTaproot.computeMastRootFromMerkleProof(script, merkleProof);
    }

    function computeMastRootFromMerkleProof(
        bytes memory script,
        bytes32[] memory merkleProof
    ) public view returns (bytes32) {
        return this._computeMastRootFromMerkleProof(script, merkleProof);
    }

    function _verifyTaprootScriptPubKey(
        bytes32 spk,
        bytes calldata script,
        bytes32[] calldata merkleProof,
        uint256 PX
    ) public pure returns (bool) {
        return
            LibTaproot.verifyTaprootScriptPubKey(spk, script, merkleProof, PX);
    }

    function verifyTaprootScriptPubKey(
        bytes32 spk,
        bytes memory script,
        bytes32[] memory merkleProof,
        uint256 PX
    ) public view returns (bool) {
        return this._verifyTaprootScriptPubKey(spk, script, merkleProof, PX);
    }
}

contract TaprootTest is Test {
    TaprootIndirection taprootIndirection = new TaprootIndirection();

    function testTaggedHashLeaf() public pure {
        bytes memory data = abi.encodePacked("catalog");
        bytes32 hash = LibTaproot.taggedHashLeaf(data);

        assertEq(
            hash,
            0x45e902fa5b1984a5edb13825d5a941d8f16d48639bd58c736907a0a626afcb56,
            "TapLeaf hashes do not match"
        );
    }

    function testTaggedHashBranch() public pure {
        bytes memory data = abi.encodePacked("catalog");
        bytes32 hash = LibTaproot.taggedHashBranch(data);

        assertEq(
            hash,
            0xf5363e304245ba2654bbc21407264c4a475866277cdffbee745903c3f3d2b72a,
            "TapBranch hashes do not match"
        );
    }

    function testTaggedHashTweak() public pure {
        bytes memory data = abi.encodePacked("catalog");
        bytes32 hash = LibTaproot.taggedHashTweak(data);

        assertEq(
            hash,
            0x778572bda6aaed8577a1c62d9c48f5447c74132a6670ed83f112522632542954,
            "TapTweak hashes do not match"
        );
    }

    function testPrecomputedTaggedHash() public pure {
        bytes memory data = abi.encodePacked("catalog");
        bytes32 tagHash = sha256(data);

        bytes32 hash = LibTaproot.precomputedTaggedHash(tagHash, data);

        assertEq(
            hash,
            0x782fabae45031960c095b43470f3bc3c6b4ee37dc22680838ebcff5c4a1b7bf5,
            "precomputedTaggedHashes do not match"
        );
    }

    function testTaggedHash() public pure {
        bytes memory data = abi.encodePacked("catalog");
        bytes32 hash = LibTaproot.taggedHash(data, data);
        assertEq(
            hash,
            0x782fabae45031960c095b43470f3bc3c6b4ee37dc22680838ebcff5c4a1b7bf5,
            "taggedHashes do not match"
        );
    }

    function testSerializeScript() public view {
        bytes
            memory script = hex"20f1835aa33781318112236f890ee427a9cea0c03b4e215900fd774c45dbc37111ac0063036f726401010a746578742f706c61696e00357b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a22646f6765222c22616d74223a2234323030227d68";

        bytes memory serialized = taprootIndirection.serializeScript(script);

        assertEq(
            serialized,
            hex"c06d20f1835aa33781318112236f890ee427a9cea0c03b4e215900fd774c45dbc37111ac0063036f726401010a746578742f706c61696e00357b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a22646f6765222c22616d74223a2234323030227d68",
            "serialized scripts do not match"
        );
    }

    function testComputeMastRootFromMerkleProof() public view {
        bytes memory script = hex"42";
        bytes32[] memory proof = new bytes32[](8);

        proof[
            0
        ] = 0x3b6cd258390f82268b0f07266ac76ef888d94366b2d51161a9c76bc23525e9f3;
        proof[
            1
        ] = 0xab11f8cd97774853013f574bef5b8aa881d927273bd32af4f180f13008b21ff6;
        proof[
            2
        ] = 0x24cc9f09e387f8e256bd1f82c6b9fd12c19c1ca738dae49f409c4ebe46b0d76d;
        proof[
            3
        ] = 0xf3bc62b6bc8a4eb61d284dbae48f5ca6d6c59100b4d0504a0655a4d73d3b4b45;
        proof[
            4
        ] = 0xc350786781aec83736c548e62ac04427a1747036cb212292bc4011aecb275e63;
        proof[
            5
        ] = 0x10a8d82f2198b631baeb29e0674d716f1ef67c38cb0ee53b3da433df32652107;
        proof[
            6
        ] = 0x863cf7b41e01a9862674a679599abf9df0233f00d054a519bc8003690d3dd20b;
        proof[
            7
        ] = 0x4f288deeda1c2ab848a4a31cbeed7e102d711d6772a954fcd7506d9d388e5307;

        bytes32 root = taprootIndirection.computeMastRootFromMerkleProof(
            script,
            proof
        );

        assertEq(
            root,
            0x2d05475b9f86146bb6337d21cd1939215700a98f3e03daa0f40e9c390acf5272,
            "computed mast roots do not match"
        );
    }

    function testShouldComputZeroSizeMerkleRoot() public view {
        bytes
            memory script = hex"205b1557b09c60a335f71e13269244abf7a5e08970d5adb5e1827864f449943c4bac0063036f7264010118746578742f706c61696e3b636861727365743d7574662d3800367b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a2261616161222c22616d74223a223130303030227d68";
        bytes32[] memory proof = new bytes32[](0);

        bytes32 root = taprootIndirection.computeMastRootFromMerkleProof(
            script,
            proof
        );

        assertEq(
            root,
            0x17b29f6c2cdc296723af89a0a4387daa7475b1e38b1518a1313c76bc10468526,
            "computed mast roots do not match"
        );
    }

    function testShouldVerifyTaprootSpk() public view {
        bytes
            memory script = hex"205b1557b09c60a335f71e13269244abf7a5e08970d5adb5e1827864f449943c4bac0063036f7264010118746578742f706c61696e3b636861727365743d7574662d3800367b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a2261616161222c22616d74223a223130303030227d68";
        bytes32[] memory proof = new bytes32[](0);
        bytes32 spk = 0x9c79fc28c5b3e354b584e39e57f9386c9137c1d58ef1644f0fbbd6724046f958;
        uint256 PX = 0x5b1557b09c60a335f71e13269244abf7a5e08970d5adb5e1827864f449943c4b;

        bool isValidTaprootKey = taprootIndirection.verifyTaprootScriptPubKey(
            spk,
            script,
            proof,
            PX
        );

        assertEq(
            isValidTaprootKey,
            true,
            "should verify taproot script pub key"
        );
    }

    function pubkeyToAddress(
        bytes memory pubkey
    ) internal pure returns (address) {
        bytes32 hash = keccak256(pubkey);
        return address(uint160(uint256(hash)));
    }

    function testShouldVerifySchnorrSignature() public pure {
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes
            memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](2);
        signature[
            0
        ] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;
        signature[
            1
        ] = 0x78fc4e9e5b9d0f0c72c832fd2c5083b2d8a5121f57637774383e43453bbebc75;

        bool verified = LibTaproot.verifySchnorr(0, PX, signature, messageHash);

        assertEq(verified, true, "Schnorr signature verification failed");
    }

    function testShouldNotVerifyInvalidParities() public {
        uint256 PX = 1;
        bytes memory message = hex"00";

        bytes32[] memory signature = new bytes32[](2);
        signature[0] = 0x00;
        signature[1] = 0x00;

        vm.expectRevert("Parity should be 0 or 1");
        LibTaproot.verifySchnorr(3, PX, signature, message);
    }

    function testShouldNotVerifySignatureWithWrongParity() public pure {
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes
            memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](2);
        signature[
            0
        ] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;
        signature[
            1
        ] = 0x78fc4e9e5b9d0f0c72c832fd2c5083b2d8a5121f57637774383e43453bbebc75;

        bool verified = LibTaproot.verifySchnorr(1, PX, signature, messageHash);

        assertEq(verified, false, "Schnorr signature verification failed");
    }

    function testShouldNotAccessWrongSignatureLength() public {
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes
            memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](1);
        signature[
            0
        ] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;

        vm.expectRevert();
        LibTaproot.verifySchnorr(1, PX, signature, messageHash);
    }

    function testShouldProduceBabylonScript() public pure {
        BabylonScriptUtils.PublicKey memory userKey = BabylonScriptUtils
            .PublicKey(
                0x4000bd2c8b975d351c5f3a42618aca31e07e2b253fcd571e9630540a3cb6eafd,
                bytes32(
                    LibEllipticCurve.deriveY(
                        0x02,
                        0x4000bd2c8b975d351c5f3a42618aca31e07e2b253fcd571e9630540a3cb6eafd,
                        LibTaproot.AA,
                        LibTaproot.BB,
                        LibTaproot.PP
                    )
                )
            );
        BabylonScriptUtils.PublicKey memory fpKey = BabylonScriptUtils
            .PublicKey(
                0x46542ccdcbde8a8c147c8d00f14d47f0d5c13c684d27497fc4610c7a4def15e5,
                bytes32(
                    LibEllipticCurve.deriveY(
                        0x02,
                        0x46542ccdcbde8a8c147c8d00f14d47f0d5c13c684d27497fc4610c7a4def15e5,
                        LibTaproot.AA,
                        LibTaproot.BB,
                        LibTaproot.PP
                    )
                )
            );

        BabylonScriptUtils.PublicKey[]
            memory fpKeys = new BabylonScriptUtils.PublicKey[](1);
        fpKeys[0] = fpKey;

        BabylonScriptUtils.PublicKey memory cKey = BabylonScriptUtils.PublicKey(
            0x4852a5d3e79cfdee1bda4ea729e879c1db0f19230eadd3cb96d3cb1efa8d30fa,
            bytes32(
                LibEllipticCurve.deriveY(
                    0x02,
                    0x4852a5d3e79cfdee1bda4ea729e879c1db0f19230eadd3cb96d3cb1efa8d30fa,
                    LibTaproot.AA,
                    LibTaproot.BB,
                    LibTaproot.PP
                )
            )
        );

        BabylonScriptUtils.PublicKey[]
            memory cKeys = new BabylonScriptUtils.PublicKey[](1);
        cKeys[0] = cKey;

        BabylonScriptUtils.BabylonScriptPaths
            memory pathscripts = BabylonScriptUtils.buildBabylonScriptPaths(
                BabylonScriptUtils.ScriptParams(userKey, fpKeys, cKeys, 1, 1000)
            );

        bytes[] memory scripts = new bytes[](3);
        scripts[0] = pathscripts.timeLockPathScript;
        scripts[1] = pathscripts.unbondingPathScript;
        scripts[2] = pathscripts.slashingPathScript;

        bytes32 pkey = LibTaproot.getTaprootScriptPubKey(
            scripts,
            0x50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0
        );

        // todo: should fix this test
        assertEq(
            pkey,
            0xb2b169d39fb8ea9828f6ed8dbbeaa12594706d03bfd1638a912608a085fdd7a5,
            "taproot script pub keys do not match"
        );
    }
}
