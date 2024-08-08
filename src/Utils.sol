// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BlockHeader} from "./Types.sol";

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
}
