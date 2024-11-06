// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BlockHeader, LibBitcoin} from "src/libraries/LibBitcoin.sol";

struct DecodeVarintFixture {
    bytes input;
    uint8 byteLength;
    bytes expected;
}

struct EncodeVarintFixture {
    uint64 input;
    bytes output;
}

contract UtilsIndirection is Test {
    function _parseBlockHeader(bytes calldata blockHeader) public pure returns (BlockHeader memory parsedHeader) {
        return LibBitcoin.parseBlockHeader(blockHeader);
    }

    function parseBlockHeader(bytes memory blockHeader) public view returns (BlockHeader memory parsedHeader) {
        return this._parseBlockHeader(blockHeader);
    }
}

contract UtilsTest is Test {
    uint256 MAX_TARGET = (0xffff) * (1 << 208);

    UtilsIndirection utilsIndirection;

    function setUp() public {
        utilsIndirection = new UtilsIndirection();
    }

    function bytes4ToBytes(bytes4 b) internal pure returns (bytes memory) {
        return bytes.concat(b[0], b[1], b[2], b[3]);
    }

    // function testShouldConvertBytesToUint() public pure {
    //     bytes memory b = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    //     uint256 number = LibBitcoin.convertBytesToUint(b);
    //     assertEq(number, UINT256_MAX, "Number does not match");
    // }

    // function testShouldNotConvertBytesToUintIfByteLengthGreaterThan32() public {
    //     bytes memory b = hex"000000000000000000000000000000000000000000000000000000000000000100";

    //     vm.expectRevert("SPVLib: length cannot be greater than 32 bytes");
    //     LibBitcoin.convertBytesToUint(b);
    // }

    function testShouldConvertToBigEndian() public pure {
        bytes memory b = hex"ffab";

        bytes memory bBE = LibBitcoin.convertToBigEndian(b);
        assertEq(bBE, hex"abff", "Big endian bytes do not match");
    }

    function testShouldComputeDoubleHash() public pure {
        bytes memory b = hex"0000000000000000000000000000000000000000000000000000000000000000";

        bytes32 bHash = LibBitcoin.doubleHash(b);

        assertEq(bHash, hex"2b32db6c2c0a6235fb1397e8225ea85e0f0e6e8c7b126d0016ccbde0e667151e", "Hash does not match");
    }

    function testShouldConvertToBytes32() public pure {
        bytes memory b = hex"000000000000000000000000000000000000000000000000000000000000000012121231";

        bytes32 b32 = LibBitcoin.convertToBytes32(b);

        assertEq(b32, hex"0000000000000000000000000000000000000000000000000000000000000000", "Bytes32 does not match");
    }

    //https://mempool.space/api/block/000000000000000000023bfd7af8a3158e100f703464ce41e4f5d24eb12706c5
    function testParseBlockHeader() public view {
        BlockHeader memory expectedHeader = BlockHeader({
            version: 0x00a03428,
            timestamp: 0x3efbb266,
            nBits: 0xbe1a0317,
            nonce: 0x48b182ba,
            previousBlockHash: 0x18dae3dc6069eed6cc2a84a94ac8197e66c005268dd101000000000000000000,
            merkleRootHash: 0x1977fa84d0689f38821e19016cb32b3ca6ab93ec885dcda968b5f2998a76b7f3
        });

        bytes memory blockHeaderHex =
            hex"00a0342818dae3dc6069eed6cc2a84a94ac8197e66c005268dd1010000000000000000001977fa84d0689f38821e19016cb32b3ca6ab93ec885dcda968b5f2998a76b7f33efbb266be1a031748b182ba";

        BlockHeader memory actualHeader = utilsIndirection.parseBlockHeader(blockHeaderHex);

        assertEq(actualHeader.version, expectedHeader.version, "Version does not match");
        assertEq(actualHeader.timestamp, expectedHeader.timestamp, "Timestamp does not match");
        assertEq(actualHeader.nBits, expectedHeader.nBits, "nBits does not match");
        assertEq(actualHeader.nonce, expectedHeader.nonce, "Nonce does not match");
        assertEq(actualHeader.previousBlockHash, expectedHeader.previousBlockHash, "Previous block hash does not match");
        assertEq(actualHeader.merkleRootHash, expectedHeader.merkleRootHash, "Merkle root hash does not match");
    }

    //https://mempool.space/api/block/000000000000000000023bfd7af8a3158e100f703464ce41e4f5d24eb12706c5
    function testConvertNBitsToTarget() public view {
        BlockHeader memory header = BlockHeader({
            version: 0x00a03428,
            timestamp: 0x3efbb266,
            nBits: 0xbe1a0317,
            nonce: 0x48b182ba,
            previousBlockHash: 0x18dae3dc6069eed6cc2a84a94ac8197e66c005268dd101000000000000000000,
            merkleRootHash: 0x1977fa84d0689f38821e19016cb32b3ca6ab93ec885dcda968b5f2998a76b7f3
        });

        uint256 target = LibBitcoin.convertnBitsToTarget(bytes4ToBytes(header.nBits));

        uint256 difficulty = MAX_TARGET / target;

        assertEq(90666502495565, difficulty, "Difficulty does not match");
    }

    function testDecodeVaruintShouldComputeProperly() public pure {
        DecodeVarintFixture[] memory fixtures = new DecodeVarintFixture[](4);

        fixtures[0] = DecodeVarintFixture({input: hex"fc", byteLength: 1, expected: hex"fc"});

        fixtures[1] = DecodeVarintFixture({input: hex"fdfd00", byteLength: 3, expected: hex"00fd"});

        fixtures[2] = DecodeVarintFixture({input: hex"fe00000100", byteLength: 5, expected: hex"00010000"});

        fixtures[3] =
            DecodeVarintFixture({input: hex"ff0000000001000000", byteLength: 9, expected: hex"0000000100000000"});

        for (uint256 i = 0; i < 4; i++) {
            (uint8 byteLength, bytes memory expected) = LibBitcoin.decodeVarint(fixtures[i].input, 0);
            assertEq(fixtures[i].byteLength, byteLength, "Byte length does not match");
            assertEq(fixtures[i].expected, expected, "Expected bytes do not match");
        }
    }

    function testEncodeVarintShouldComputeProperly() public pure {
        EncodeVarintFixture[] memory fixtures = new EncodeVarintFixture[](4);

        fixtures[0] = EncodeVarintFixture({input: 0xfc, output: hex"fc"});

        fixtures[1] = EncodeVarintFixture({input: 0x00fd, output: hex"fdfd00"});

        fixtures[2] = EncodeVarintFixture({input: 0x00010000, output: hex"fe00000100"});

        fixtures[3] = EncodeVarintFixture({input: 0x0000000100000000, output: hex"ff0000000001000000"});

        for (uint256 i = 0; i < 4; i++) {
            bytes memory expected = LibBitcoin.encodeVarint(fixtures[i].input);
            assertEq(fixtures[i].output, expected, "Expected bytes do not match");
        }
    }
}
