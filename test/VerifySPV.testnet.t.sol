// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {LibBitcoin, BlockHeader} from "src/libraries/LibBitcoin.sol";
import {LibSPV} from "src/libraries/LibSPV.sol";
import {VerifySPV} from "src/VerifySPV.sol";
import {Test} from "forge-std/Test.sol";
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
    using LibSPV for BlockHeader;

    BlockHeader[] difficultyEpoch;
    VerifySPV verifySPV;

    event BlockRegistered(bytes32 blockHash);

    function setUp() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/fixtures/difficultyEpoch_testnet.json");
        string memory json = vm.readFile(path);

        (FixtureBlockHeader[] memory f) = abi.decode(json.parseRaw(""), (FixtureBlockHeader[]));
        for (uint256 i = 0; i < f.length; i++) {
            difficultyEpoch.push(toBlockHeader(f[i]));
        }
        verifySPV = new VerifySPV(difficultyEpoch[0], 0, 1, true);
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

    // function testShouldVerifyAnEpochInTestnet() public {
    //     for (uint256 i = 0; i < 28; i++) {
    //         (BlockHeader[] memory epoch) = new BlockHeader[](76);
    //         for (uint256 j = 0; j < 76; j++) {
    //             epoch[j] = difficultyEpoch[i * 72 + j];
    //         }

    //         verifySPV.registerLatestBlock(epoch, 10);
    //     }

    //     // assertEq(verifySPV.epoch(), 28, "Epoch should be 28");
    // }
}
