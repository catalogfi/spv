// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Utils} from "src/Utils.sol";
import {SPVLib} from "src/libraries/SPVLib.sol";
import {BlockHeader} from "src/Types.sol";
import {VerifySPV} from "src/VerifySPV.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "forge-std/StdJson.sol";

struct FixtureBlockHeader {
    bytes32 merkleRootHash;
    bytes nBits;
    bytes nonce;
    bytes32 previousBlockHash;
    bytes timestamp;
    bytes version;
}

contract VerifySPVTest is Test {
    using stdJson for string;
    using Math for uint256;
    using SPVLib for BlockHeader;

    BlockHeader[] difficultyEpoch;
    VerifySPV verifySPV;

    event BlockRegistered(bytes32 blockHash);

    function setUp() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/fixtures/difficultyEpoch.json");
        string memory json = vm.readFile(path);

        (FixtureBlockHeader[] memory f) = abi.decode(json.parseRaw(""), (FixtureBlockHeader[]));
        for (uint256 i = 0; i < f.length; i++) {
            difficultyEpoch.push(toBlockHeader(f[i]));
        }
        verifySPV = new VerifySPV(difficultyEpoch[0], true);
    }

    function toBlockHeader(FixtureBlockHeader memory f) private pure returns (BlockHeader memory) {
        return BlockHeader({
            version: bytes4(f.version),
            previousBlockHash: f.previousBlockHash,
            merkleRootHash: f.merkleRootHash,
            timestamp: bytes4(f.timestamp),
            nBits: bytes4(f.nBits),
            nonce: bytes4(f.nonce)
        });
    }

    function testRegisterBlock() public {
        BlockHeader[] memory epoch1 = new BlockHeader[](76);
        BlockHeader[] memory epoch2 = new BlockHeader[](76);

        uint256 counter = 0;

        while (counter < 76) {
            epoch1[counter] = difficultyEpoch[counter];
            counter++;
        }

        counter = 72;
        while (counter < 72 + 76) {
            epoch2[counter - 72] = difficultyEpoch[counter];
            counter++;
        }

        vm.expectEmit(false, false, false, true, address(verifySPV));
        emit BlockRegistered(epoch1[72].calculateBlockHash());
        verifySPV.registerBlock(epoch1);

        vm.expectEmit(false, false, false, true, address(verifySPV));
        emit BlockRegistered(epoch2[72].calculateBlockHash());
        verifySPV.registerBlock(epoch2);
    }

    function testShouldntRegisterInvalidBlock() public {
        (BlockHeader[] memory epoch) = new BlockHeader[](76);

        uint256 counter = 0;

        while (counter < 76) {
            epoch[counter] = difficultyEpoch[counter];
            counter++;
        }

        epoch[2].previousBlockHash = epoch[3].previousBlockHash;

        vm.expectRevert("VerifySPV: sequence verification failed");
        verifySPV.registerBlock(epoch);
    }

    function testRegisterBlockShouldRejectInvalidEpochLength() public {
        (BlockHeader[] memory epoch) = new BlockHeader[](3);
        vm.expectRevert("VerifySPV: invalid epoch, should contain previous 72 blocks and next 3 blocks");
        verifySPV.registerBlock(epoch);
    }

    function tesRegisterBlockShouldRejectIfStartingBlockNotOnChain() public {
        (BlockHeader[] memory epoch) = new BlockHeader[](76);

        uint256 counter = 0;

        while (counter < 76) {
            epoch[counter] = difficultyEpoch[counter + 1];
            counter++;
        }

        vm.expectRevert("VerifySPV: invalid epoch, starting block not on chain");
        verifySPV.registerBlock(epoch);
    }

    function testVerifyTransactionInBlock() public {
        BlockHeader[] memory epoch = new BlockHeader[](76);
        BlockHeader[] memory epochForTxVerification = new BlockHeader[](73);
        uint256 counter = 0;

        while (counter < 76) {
            epoch[counter] = difficultyEpoch[counter];
            if (counter < 73) epochForTxVerification[counter] = difficultyEpoch[counter];
            counter++;
        }

        verifySPV.registerBlock(epoch);
        bytes32[] memory proof = new bytes32[](12);

        proof[0] = bytes32(0x1a62992f9e3d1dcb699845cbee5d23569a13981ffbfd2c7c518be65821eaef06);
        proof[1] = bytes32(0x0c7652d6747faf960a42ed0345112140ad26a5d9cb7f0955b6ddd5c70d8ae6f5);
        proof[2] = bytes32(0xc7ba8b5b36d6eec2f350d0c72af6f1280e7fc05e767b5ac05d2bc606daebf065);
        proof[3] = bytes32(0x2bb7498551304f67657656fabfc66f92e60775040775f93d616c91e9cbfcb1c4);
        proof[4] = bytes32(0xaac8a3c0eac8f5a9eb25451a56bbf6134f4719c99460a7d892a4790fbc56d69f);
        proof[5] = bytes32(0xda071e5e721ac7a6eda6002feba70bf26700d3f39919b2dc5cf927a514b46fed);
        proof[6] = bytes32(0x50f4afabbecb0d3cfdcb2d19170a198662b78f00b9899ceaf5b270de0c52b4da);
        proof[7] = bytes32(0x75b5fc80d4bb258ef53691ad6eac624f6e274e85eec00f02aecf01bcf0947382);
        proof[8] = bytes32(0x257cd93d8ac8a403e09290c8236bfe951bb6d5944799b141b095258f4e71a3ab);
        proof[9] = bytes32(0x8a3c6629f70a22d0dff99e6feff7516d729baf4bb52583673685e655aa80cf4c);
        proof[10] = bytes32(0x5f372e5db7d25a390f2cb62243acbe107023c262b13db2f329c6a6780e4ab3b4);
        proof[11] = bytes32(0x5a3721a753244c9c41f44e4a41424f05dd8be93b97c518eb5f5286bc7ade3c7a);

        bool isIncluded = verifySPV.verifyTxInclusion(
            epochForTxVerification, 3, 636, 0x723026cc979bb3b82d1c1749450a66444e17f66bfe7bc2188bc2b2fc5ad8a8a3, proof
        );

        assertEq(isIncluded, true, "Transaction should be included in block");
    }

    function testShouldRejectIfInvalidEpochLength() public {
        BlockHeader[] memory epochForTxVerification = new BlockHeader[](1);
        epochForTxVerification[0] = difficultyEpoch[0];

        vm.expectRevert("VerifySPV: inclusion verification needs all 72 blocks in the epoch");
        verifySPV.verifyTxInclusion(
            epochForTxVerification,
            0,
            0,
            0x723026cc979bb3b82d1c1749450a66444e17f66bfe7bc2188bc2b2fc5ad8a8a3,
            new bytes32[](12)
        );
    }

    function testShouldntVerifyIfInvalidStartingBlock() public {
        BlockHeader[] memory epoch = new BlockHeader[](76);
        BlockHeader[] memory epochForTxVerification = new BlockHeader[](73);

        uint256 counter = 0;

        while (counter < 76) {
            epoch[counter] = difficultyEpoch[counter];
            if (counter < 73) epochForTxVerification[counter] = difficultyEpoch[counter + 1];
            counter++;
        }

        verifySPV.registerBlock(epoch);

        vm.expectRevert("VerifySPV: invalid epoch, starting block not on chain");
        verifySPV.verifyTxInclusion(
            epochForTxVerification,
            3,
            636,
            0x723026cc979bb3b82d1c1749450a66444e17f66bfe7bc2188bc2b2fc5ad8a8a3,
            new bytes32[](12)
        );
    }

    function testShouldntVerifyInvalidEndingBlock() public {
        BlockHeader[] memory epochForTxVerification = new BlockHeader[](73);

        uint256 counter = 0;

        while (counter < 76) {
            if (counter < 73) epochForTxVerification[counter] = difficultyEpoch[counter];
            counter++;
        }

        vm.expectRevert("VerifySPV: invalid epoch, ending block not on chain");
        verifySPV.verifyTxInclusion(
            epochForTxVerification,
            3,
            636,
            0x723026cc979bb3b82d1c1749450a66444e17f66bfe7bc2188bc2b2fc5ad8a8a3,
            new bytes32[](12)
        );
    }

    function testShouldntVerifyInvalidTransaction() public {
        BlockHeader[] memory epoch = new BlockHeader[](76);
        BlockHeader[] memory epochForTxVerification = new BlockHeader[](73);
        uint256 counter = 0;

        while (counter < 76) {
            epoch[counter] = difficultyEpoch[counter];
            if (counter < 73) epochForTxVerification[counter] = difficultyEpoch[counter];
            counter++;
        }

        verifySPV.registerBlock(epoch);
        bytes32[] memory proof = new bytes32[](12);

        proof[0] = bytes32(0x1a62992f9e3d1dcb699845cbee5d23569a13981ffbfd2c7c518be65821eaef06);
        proof[1] = bytes32(0x0c7652d6747faf960a42ed0345112140ad26a5d9cb7f0955b6ddd5c70d8ae6f5);
        proof[2] = bytes32(0xc7ba8b5b36d6eec2f350d0c72af6f1280e7fc05e767b5ac05d2bc606daebf065);
        proof[3] = bytes32(0x2bb7498551304f67657656fabfc66f92e60775040775f93d616c91e9cbfcb1c4);
        proof[4] = bytes32(0xaac8a3c0eac8f5a9eb25451a56bbf6134f4719c99460a7d892a4790fbc56d69f);
        proof[5] = bytes32(0xda071e5e721ac7a6eda6002feba70bf26700d3f39919b2dc5cf927a514b46fed);
        proof[6] = bytes32(0x50f4afabbecb0d3cfdcb2d19170a198662b78f00b9899ceaf5b270de0c52b4da);
        proof[7] = bytes32(0x75b5fc80d4bb258ef53691ad6eac624f6e274e85eec00f02aecf01bcf0947382);
        proof[8] = bytes32(0x257cd93d8ac8a403e09290c8236bfe951bb6d5944799b141b095258f4e71a3ab);
        proof[9] = bytes32(0x8a3c6629f70a22d0dff99e6feff7516d729baf4bb52583673685e655aa80cf4c);
        proof[10] = bytes32(0x5f372e5db7d25a390f2cb62243acbe107023c262b13db2f329c6a6780e4ab3b4);
        proof[11] = bytes32(0x5a3721a753244c9c41f44e4a41424f05dd8be93b97c518eb5f5286bc7ade3c7a);

        bool isIncluded = verifySPV.verifyTxInclusion(
            epochForTxVerification,
            3,
            636,
            bytes32(
                Utils.convertToBigEndian(
                    bytes.concat(bytes32(0x723026cc979bb3b82d1c1749450a66444e17f66bfe7bc2188bc2b2fc5ad8a8a3))
                )
            ),
            proof
        );

        assertEq(isIncluded, false, "Transaction should be included in block");
    }

    function testShouldAdjustNewDifficulty() public {
        for (uint256 i = 0; i < 28; i++) {
            (BlockHeader[] memory epoch) = new BlockHeader[](76);
            for (uint256 j = 0; j < 76; j++) {
                epoch[j] = difficultyEpoch[i * 72 + j];
            }

            verifySPV.registerBlock(epoch);
        }

        assertEq(verifySPV.epoch(), 28, "Epoch should be 28");
    }

    function testShouldntVerifyInvalidDifficultyEpoch() public {
        for (uint256 i = 0; i < 28; i++) {
            (BlockHeader[] memory epoch) = new BlockHeader[](76);
            for (uint256 j = 0; j < 76; j++) {
                epoch[j] = difficultyEpoch[i * 72 + j];
            }

            if (i == 27) {
                epoch[2].previousBlockHash = epoch[3].previousBlockHash;
                vm.expectRevert("VerifySPV: pre subsequence in difficulty epoch failed");
                verifySPV.registerBlock(epoch);
            } else {
                verifySPV.registerBlock(epoch);
            }
        }

        assertEq(verifySPV.epoch(), 27, "Epoch should be 27");
    }

    function testShouldntVerifyInvalidDifficultyEpochTarget() public {
        for (uint256 i = 0; i < 28; i++) {
            (BlockHeader[] memory epoch) = new BlockHeader[](76);
            for (uint256 j = 0; j < 76; j++) {
                epoch[j] = difficultyEpoch[i * 72 + j];
            }

            if (i == 27) {
                epoch[72].timestamp = difficultyEpoch[0].timestamp;
                vm.expectRevert("VerifySPV: adjusted difficulty is not in allowed range");
                verifySPV.registerBlock(epoch);
            } else {
                verifySPV.registerBlock(epoch);
            }
        }

        assertEq(verifySPV.epoch(), 27, "Epoch should be 27");
    }

    function testShouldntVerifyInvalidDifficultyBlockPreviousHash() public {
        for (uint256 i = 0; i < 28; i++) {
            (BlockHeader[] memory epoch) = new BlockHeader[](76);
            for (uint256 j = 0; j < 76; j++) {
                epoch[j] = difficultyEpoch[i * 72 + j];
            }

            if (i == 27) {
                epoch[72].previousBlockHash = difficultyEpoch[0].previousBlockHash;
                vm.expectRevert("VerifySPV: difficulty epoch validation failed");
                verifySPV.registerBlock(epoch);
            } else {
                verifySPV.registerBlock(epoch);
            }
        }

        assertEq(verifySPV.epoch(), 27, "Epoch should be 27");
    }

    function testShouldntVerifyInvalidPostSequenceInDifficultyEpoch() public {
        for (uint256 i = 0; i < 28; i++) {
            (BlockHeader[] memory epoch) = new BlockHeader[](76);
            for (uint256 j = 0; j < 76; j++) {
                epoch[j] = difficultyEpoch[i * 72 + j];
            }

            if (i == 27) {
                epoch[74].previousBlockHash = epoch[3].previousBlockHash;
                vm.expectRevert("VerifySPV: post subsequence in difficulty epoch failed");
                verifySPV.registerBlock(epoch);
            } else {
                verifySPV.registerBlock(epoch);
            }
        }

        assertEq(verifySPV.epoch(), 27, "Epoch should be 27");
    }
}
