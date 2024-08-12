// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SPVLib} from "src/libraries/SPVLib.sol";
import {Utils} from "src/Utils.sol";
import {BlockHeader} from "src/Types.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct VerifyTx {
    bytes32[] merkle;
    uint256 pos;
    bytes32 txHash;
}

contract SPVLibIndirection is Test {
    function _verifyWork(BlockHeader calldata header, bool isMainnet) public pure returns (bool) {
        return SPVLib.verifyWork(header, isMainnet);
    }

    function verifyWork(BlockHeader memory header, bool isMainnet) public view returns (bool) {
        return this._verifyWork(header, isMainnet);
    }

    function _calculateNewTarget(BlockHeader calldata header, uint256 LDEtarget, bytes4 LDETimestamp)
        public
        pure
        returns (uint256)
    {
        return SPVLib.calculateNewTarget(header, LDEtarget, LDETimestamp);
    }

    function calculateNewTarget(BlockHeader memory header, uint256 LDEtarget, bytes4 LDETimestamp)
        public
        view
        returns (uint256)
    {
        return this._calculateNewTarget(header, LDEtarget, LDETimestamp);
    }
}

contract SPVLibTestTest is Test {
    using stdJson for string;

    SPVLibIndirection spvLibIndirection;

    function setUp() public {
        spvLibIndirection = new SPVLibIndirection();
    }

    function bytes4ToBytes(bytes4 b) internal pure returns (bytes memory) {
        return bytes.concat(b[0], b[1], b[2], b[3]);
    }

    //https://mempool.space/api/block/00000000000000000001d2cbad2209f51143679b6797aef393a45e82eb88a9ae
    function testCalculateBlockHash() public pure {
        BlockHeader memory header = BlockHeader({
            version: 0x04e00020,
            timestamp: 0x881c2966,
            nBits: 0xdb310317,
            nonce: 0x2b1d1f06,
            previousBlockHash: 0x4be80184cc04d777daad1189724bc32a949e04601ebf02000000000000000000,
            merkleRootHash: 0x78ce8a1195d00b58c530046ec369868aa4cc856bf139ef2636192ced886ed412
        });

        bytes32 blockHash = SPVLib.calculateBlockHash(header);

        assertEq(
            0xaea988eb825ea493f3ae97679b674311f50922adcbd201000000000000000000, blockHash, "Block hash does not match"
        );
    }

    //https://mempool.space/api/block/000000000000000000023bfd7af8a3158e100f703464ce41e4f5d24eb12706c5
    function testVerifyProof() public view {
        BlockHeader memory header = BlockHeader({
            version: 0x00a03428,
            timestamp: 0x3efbb266,
            nBits: 0xbe1a0317,
            nonce: 0x48b182ba,
            previousBlockHash: 0x18dae3dc6069eed6cc2a84a94ac8197e66c005268dd101000000000000000000,
            merkleRootHash: 0x1977fa84d0689f38821e19016cb32b3ca6ab93ec885dcda968b5f2998a76b7f3
        });

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/fixtures/txs.json");
        string memory json = vm.readFile(path);

        (VerifyTx[] memory txs) = abi.decode(json.parseRaw(""), (VerifyTx[]));

        for (uint256 i = 0; i < txs.length; i++) {
            assertEq(
                SPVLib.verifyProof(header, txs[i].txHash, txs[i].pos, txs[i].merkle),
                true,
                string.concat("Failed to verify proof for tx", Strings.toString(i))
            );
        }
    }

    //https://mempool.space/api/block/000000000000000000023bfd7af8a3158e100f703464ce41e4f5d24eb12706c5
    function testVerifyWork() public view {
        BlockHeader memory header = BlockHeader({
            version: 0x00a03428,
            timestamp: 0x3efbb266,
            nBits: 0xbe1a0317,
            nonce: 0x48b182ba,
            previousBlockHash: 0x18dae3dc6069eed6cc2a84a94ac8197e66c005268dd101000000000000000000,
            merkleRootHash: 0x1977fa84d0689f38821e19016cb32b3ca6ab93ec885dcda968b5f2998a76b7f3
        });

        assertEq(spvLibIndirection.verifyWork(header, true), true, "Work verification failed");
    }

    //https://mempool.space/api/block/00000000000000000001d2cbad2209f51143679b6797aef393a45e82eb88a9ae
    //https://mempool.space/api/block/000000000000000000026b90d09b5e4fba615eadfc4ce2a19f6a68c9c18d4a2e
    function testCalculateNewTarget() public view {
        BlockHeader memory oldHeader = BlockHeader({
            version: 0x04e00020,
            timestamp: 0x881c2966,
            nBits: 0xdb310317,
            nonce: 0x2b1d1f06,
            previousBlockHash: 0x4be80184cc04d777daad1189724bc32a949e04601ebf02000000000000000000,
            merkleRootHash: 0x78ce8a1195d00b58c530046ec369868aa4cc856bf139ef2636192ced886ed412
        });

        uint256 oldTarget = Utils.convertnBitsToTarget(bytes4ToBytes(oldHeader.nBits));

        BlockHeader memory newHeader = BlockHeader({
            version: 0x00e0ff27,
            timestamp: 0xbeac3c66,
            nBits: 0x9a620317,
            nonce: 0xa36e82cc,
            previousBlockHash: 0x4c1203a5b0b71f57ecb9531a3485ed0339c87cb7421302000000000000000000,
            merkleRootHash: 0x62b1722003bc3159639f60e540d79fb62a3939a6df0f398fe7976608f78770d9
        });

        uint256 actualNewTarget = spvLibIndirection.calculateNewTarget(newHeader, oldTarget, oldHeader.timestamp);
        uint256 expectedNewTarget = Utils.convertnBitsToTarget(bytes4ToBytes(newHeader.nBits));

        assertEq(
            SPVLib.verifyDifficultyEpochTarget(expectedNewTarget, actualNewTarget), true, "New target does not match"
        );
    }
}
