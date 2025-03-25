// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

struct BlockHeader {
    bytes4 version;
    bytes32 previousBlockHash;
    bytes32 merkleRootHash;
    bytes4 timestamp;
    bytes4 nBits;
    bytes4 nonce;
}

struct Outpoint {
    bytes spk;
    uint32 amount;
}

struct Prevout {
    bytes32 txid;
    uint32 vout;
}

library LibBitcoin {
    function convertToBigEndian(bytes memory bytesLE) internal pure returns (bytes memory) {
        uint256 length = bytesLE.length;
        bytes memory bytesBE = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytesBE[length - i - 1] = bytesLE[i];
        }
        return bytesBE;
    }

    function convertnBitsToTarget(bytes memory nBitsBytes) internal pure returns (uint256) {
        uint256 nBits = bytesToUint256((convertToBigEndian(nBitsBytes)));
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

    function bytesToUint256(bytes memory data) public pure returns (uint256 result) {
        require(data.length <= 32, "Input bytes length must be <= 32");

        assembly {
            let length := mload(data)

            if gt(length, 0) {
                // Add 0x20 to skip the length prefix of the bytes array
                result := mload(add(data, 0x20))

                // Shift right to account for any bytes less than 32
                let shift := mul(sub(32, length), 8)
                result := shr(shift, result)
            }
        }
    }

    function parseTx(bytes calldata txHex) public pure returns (bytes32, Prevout[] memory, Outpoint[] memory) {
        (uint256 offset, Prevout[] memory prevouts) = parsePrevouts(txHex, 6);
        (uint256 outPointoffset, Outpoint[] memory outpoints) = parseOutpoints(txHex, offset);
        bytes32 txId = calculateTxId(txHex, outPointoffset);

        return (txId, prevouts, outpoints);
    }

    // Parse transaction inputs (prevouts)
    function parsePrevouts(bytes calldata txHex, uint256 startOffset)
        public
        pure
        returns (uint256 offset, Prevout[] memory prevouts)
    {
        offset = startOffset;

        (uint8 bytesLength, bytes memory numInputs) = decodeVarint(txHex, offset);
        offset += bytesLength;

        uint256 inputCount = bytesToUint256(numInputs);
        prevouts = new Prevout[](inputCount);

        for (uint256 i = 0; i < inputCount; i++) {
            (offset, prevouts[i]) = parseSinglePrevout(txHex, offset);
        }
    }

    // Parse a single prevout
    function parseSinglePrevout(bytes calldata txHex, uint256 offset)
        public
        pure
        returns (uint256 newOffset, Prevout memory prevout)
    {
        prevout.txid = bytes32(convertToBigEndian(txHex[offset:offset + 32]));
        prevout.vout = uint32(bytes4(convertToBigEndian(txHex[offset + 32:offset + 36])));
        offset += 36;

        // Handle scriptSig
        (uint8 scriptSigLength, bytes memory scriptSigValue) = decodeVarint(txHex, offset);
        offset += scriptSigLength;
        offset += bytesToUint256(scriptSigValue);

        // Skip sequence
        offset += 4;

        newOffset = offset;
    }

    // Parse transaction outputs
    function parseOutpoints(bytes calldata txHex, uint256 startOffset)
        public
        pure
        returns (uint256 offset, Outpoint[] memory outpoints)
    {
        offset = startOffset;

        (uint8 outputsLength, bytes memory numOutputs) = decodeVarint(txHex, offset);
        offset += outputsLength;

        uint256 outputCount = bytesToUint256(numOutputs);
        outpoints = new Outpoint[](outputCount);

        for (uint256 i = 0; i < outputCount; i++) {
            (offset, outpoints[i]) = parseSingleOutpoint(txHex, offset);
        }
    }

    // Parse a single outpoint
    function parseSingleOutpoint(bytes calldata txHex, uint256 offset)
        public
        pure
        returns (uint256 newOffset, Outpoint memory outpoint)
    {
        outpoint.amount = uint32(bytesToUint256(convertToBigEndian(bytes(txHex[offset:offset + 8]))));
        offset += 8;

        (uint8 spkByteLength, bytes memory spkLength) = decodeVarint(txHex, offset);
        offset += spkByteLength;

        uint256 spkLengthValue = bytesToUint256(spkLength);
        outpoint.spk = txHex[offset:offset + spkLengthValue];
        offset += spkLengthValue;

        newOffset = offset;
    }

    // Calculate transaction ID
    function calculateTxId(bytes calldata txHex, uint256 offset) public pure returns (bytes32) {
        bytes memory txWithoutWitness = bytes.concat(txHex[:4], txHex[6:offset], txHex[txHex.length - 4:]);

        bytes memory txIdInNaturalByteOrder = abi.encodePacked(sha256(abi.encodePacked(sha256(txWithoutWitness))));

        return bytes32(convertToBigEndian(txIdInNaturalByteOrder));
    }
}
