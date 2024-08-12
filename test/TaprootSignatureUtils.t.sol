// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TaprootSignatureUtils} from "src/libraries/TaprootSignatureUtils.sol";
import {EllipticCurve} from "src/libraries/EllipticCurve.sol";
import {console} from "forge-std/console.sol";

contract TaprootSignatureUtilsTest is Test {
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    function pubkeyToAddress(bytes memory pubkey) internal pure returns (address) {
        bytes32 hash = keccak256(pubkey);
        return address(uint160(uint256(hash)));
    }

    function testShouldVerifySchnorrSignature() public pure {
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](2);
        signature[0] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;
        signature[1] = 0x78fc4e9e5b9d0f0c72c832fd2c5083b2d8a5121f57637774383e43453bbebc75;

        bool verified = TaprootSignatureUtils.verifySchnorr(0, PX, signature, messageHash);

        assertEq(verified, true, "Schnorr signature verification failed");
    }

    function testShouldNotVerifyInvalidParities() public {
        uint256 PX = 1;
        bytes memory message = hex"00";

        bytes32[] memory signature = new bytes32[](2);
        signature[0] = 0x00;
        signature[1] = 0x00;

        vm.expectRevert("Parity should be 0 or 1");
        TaprootSignatureUtils.verifySchnorr(3, PX, signature, message);
    }

    function testShouldNotVerifySignatureWithWrongParity() public pure {
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](2);
        signature[0] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;
        signature[1] = 0x78fc4e9e5b9d0f0c72c832fd2c5083b2d8a5121f57637774383e43453bbebc75;

        bool verified = TaprootSignatureUtils.verifySchnorr(1, PX, signature, messageHash);

        assertEq(verified, false, "Schnorr signature verification failed");
    }

    function testShouldNotAccessWrongSignatureLength() public { 
        uint256 PX = 0x21ef19b8f9258d0b012d16112b2f4741d37f0da7c14a048b7c4209439b40c1ad;
        bytes memory messageHash = hex"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

        bytes32[] memory signature = new bytes32[](1);
        signature[0] = 0x83df236a5434e4d710f70813f06c2e09730015323f7dbd9e27e111e4fc2a254e;

        vm.expectRevert();
        TaprootSignatureUtils.verifySchnorr(1, PX, signature, messageHash);
    }
}
