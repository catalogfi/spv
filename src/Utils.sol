// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BlockHeader} from "./Types.sol";
import {console} from "forge-std/console.sol";

library Utils {
    function convertBytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        uint256 length = b.length;
        require(length <= 32, "SPVLib: length cannot be greater than 32 bytes");
        for (uint256 i = 0; i < length; i++) {
            number = number + uint256(uint8(b[i])) * (2 ** (8 * (length - (i + 1))));
        }
        return number;
    }

    function convertToBigEndian(bytes memory bytesLE) internal pure returns (bytes memory) {
        uint256 length = bytesLE.length;
        bytes memory bytesBE = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytesBE[length - i - 1] = bytesLE[i];
        }
        return bytesBE;
    }

    function convertnBitsToTarget(bytes memory nBitsBytes) internal pure returns (uint256) {
        uint256 nBits = convertBytesToUint(convertToBigEndian(nBitsBytes));
        uint256 exp = uint256(nBits) >> 24;
        uint256 c = nBits & 0xffffff;
        uint256 target = uint256((c * 2 ** (8 * (exp - 3))));
        return target;
    }

    function doubleHash(bytes memory data) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(abi.encodePacked(data))));
    }

    function convertToBytes32(bytes memory data) internal pure returns (bytes32 result) {
        assembly {
            // Copy 32 bytes from data into result
            result := mload(add(data, 32))
        }
    }

    function parseBlockHeader(bytes calldata blockHeader) internal pure returns (BlockHeader memory parsedHeader) {
        parsedHeader.version = bytes4(blockHeader[:4]);
        parsedHeader.previousBlockHash = bytes32(blockHeader[4:36]);
        parsedHeader.merkleRootHash = bytes32(blockHeader[36:68]);
        parsedHeader.timestamp = bytes4(blockHeader[68:72]);
        parsedHeader.nBits = bytes4(blockHeader[72:76]);
        parsedHeader.nonce = bytes4(blockHeader[76:]);
    }

    function decodeVarint(bytes calldata data, uint256 offset) public pure returns (uint8, bytes memory) {
        if (data[offset] < 0xfd) {
            return (0x01, data[offset:offset + 1]);
        } else if (data[offset] == 0xfd) {
            return (0x03, convertToBigEndian(data[offset + 1:offset + 1 + 2]));
        } else if (data[offset] == 0xfe) {
            return (0x05, convertToBigEndian(data[offset + 1:offset + 1 + 4]));
        } else {
            return (0x09, convertToBigEndian(data[offset + 1:offset + 1 + 8]));
        }
    }

    function encodeVarint(uint64 number) public pure returns (bytes memory) {
        if (number < 0xfd) {
            return convertToBigEndian(abi.encodePacked(uint8(number)));
        } else if (number <= 0xffff) {
            return abi.encodePacked(bytes1(0xfd), convertToBigEndian(abi.encodePacked(uint16(number))));
        } else if (number <= 0xffffffff) {
            return abi.encodePacked(bytes1(0xfe), convertToBigEndian(abi.encodePacked(uint32(number))));
        } else {
            return abi.encodePacked(bytes1(0xff), convertToBigEndian(abi.encodePacked(uint64(number))));
        }
    }
}
