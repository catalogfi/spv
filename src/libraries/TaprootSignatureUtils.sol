// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {EllipticCurve} from "./EllipticCurve.sol";
import {console} from "forge-std/console.sol";

library TaprootSignatureUtils {
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    uint256 public constant OO = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    bytes32 public constant BIP340_CHALLENGE_HASH = 0x7BB52D7A9FEF58323EB1BF7A407DB382D2F3F2D81BB1224F49FE518F6D48D37C;

    function pubkeyToAddress(bytes memory pubkey) internal pure returns (address) {
        bytes32 hash = keccak256(pubkey);
        return address(uint160(uint256(hash)));
    }

    function verifySchnorr(uint8 parity, uint256 PX, bytes32[] memory signature, bytes memory message)
        external
        pure
        returns (bool)
    {
        require(parity < 2, "Parity should be 0 or 1");
        require(signature.length == 2, "Signature should be an array of length 2, [R, s]");

        uint256 RX = uint256(signature[0]);
        uint256 s = uint256(signature[1]);

        uint256 RY = EllipticCurve.deriveY(0x02, RX, AA, BB, PP);

        bytes32 messageChallenge = sha256(bytes.concat(BIP340_CHALLENGE_HASH, BIP340_CHALLENGE_HASH, bytes32(RX), bytes32(PX), message));

        bytes32 sP_x = bytes32(OO - mulmod(s, PX, OO));
        bytes32 eP_x = bytes32(OO - mulmod(uint256(messageChallenge), PX, OO));

        address computedAddress = ecrecover(sP_x, parity + 27, bytes32(PX), eP_x);

        require(computedAddress != address(0), "Invalid signature");

        return pubkeyToAddress(abi.encodePacked(RX, RY)) == computedAddress;
    }
}
