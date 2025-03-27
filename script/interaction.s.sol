pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VerifySPV, BlockHeader, LibBitcoin} from "../src/VerifySPV.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import "forge-std/StdJson.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol";

contract SPVInteraction is Script {
    using stdJson for string;

    BlockHeader[] difficultyEpoch;

    VerifySPV verifySPV = VerifySPV(address(0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1));

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 1; i < 6; i++) {
            string memory base = string.concat("[", vm.toString(i), "]");

            BlockHeader memory header;
            header.version = bytes4(stdJson.readBytes(json, string.concat(base, ".version")));
            header.previousBlockHash = stdJson.readBytes32(json, string.concat(base, ".previousblockhash"));
            header.merkleRootHash = stdJson.readBytes32(json, string.concat(base, ".merkleroot"));
            header.timestamp = bytes4(stdJson.readBytes(json, string.concat(base, ".time")));
            header.nBits = bytes4(stdJson.readBytes(json, string.concat(base, ".bits")));
            header.nonce = bytes4(stdJson.readBytes(json, string.concat(base, ".nonce")));

            difficultyEpoch.push(header);
            // printBlockHeader(header);
        }

        // registerBlockAtEnd();
        // insertBlockInBetween();
        checkTrxIncluded();
    }

    function registerBlockAtEnd() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        verifySPV.registerLatestBlock(difficultyEpoch, 4);
        vm.stopBroadcast();
    }

    function insertBlockInBetween() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        verifySPV.registerInclusiveBlock(difficultyEpoch, 1);
        vm.stopBroadcast();
    }

    function checkTrxIncluded() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        bytes32[] memory proof = new bytes32[](4);

        // proof[0] = 0x38bd7060444f0dca106fbf37ceeb83c29b271faf6777f635777bb07b0db224fb;
        proof[0] = 0xc308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e;
        proof[1] = 0xf2d8822c7c4d16f185333d31534de1238b14154faf33796f62ae05d191188b88;
        proof[2] = 0x9b5ff453452016268981b0ea0bfbb972b0a39f98c12233cdc803c0febf42942c;
        proof[3] = 0x2e7fc9543eb703c29ba44f9aef22ea0dfc6763b5df5feb4a3f9c99025751ca55;

        uint256 x = verifySPV.verifyTxInclusion(
            difficultyEpoch, 1, 0, 0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b, proof
        );
        // assert(x == 5);
        vm.stopBroadcast();
    }
}
