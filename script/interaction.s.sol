pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VerifySPV, BlockHeader, LibBitcoin} from "../src/VerifySPV.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import "forge-std/StdJson.sol";

contract SPVInteraction is Script {
    using stdJson for string;

    BlockHeader[] difficultyEpoch;

    VerifySPV verifySPV =
        VerifySPV(address(0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82));

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 1; i < 6; i++) {
            string memory base = string.concat("[", vm.toString(i), "]");

            BlockHeader memory header;
            header.version = bytes4(
                stdJson.readBytes(json, string.concat(base, ".version"))
            );
            header.previousBlockHash = stdJson.readBytes32(
                json,
                string.concat(base, ".previousblockhash")
            );
            header.merkleRootHash = stdJson.readBytes32(
                json,
                string.concat(base, ".merkleroot")
            );
            header.timestamp = bytes4(
                stdJson.readBytes(json, string.concat(base, ".time"))
            );
            header.nBits = bytes4(
                stdJson.readBytes(json, string.concat(base, ".bits"))
            );
            header.nonce = bytes4(
                stdJson.readBytes(json, string.concat(base, ".nonce"))
            );

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
        bytes32[] memory proof = new bytes32[](1);

        // proof[0] = 0x38bd7060444f0dca106fbf37ceeb83c29b271faf6777f635777bb07b0db224fb;
        proof[0] = 0x86560b23cf85525bb9f9a890e0d4bb809f564e5e623bbf621ccd6246e1953e55;

        uint256 x = verifySPV.verifyTxInclusion(difficultyEpoch, 1,1, 0x244fd62704eb0158eb3696fa2f72c25674d51ef465acdee137cbdb69ce1b7891, proof);
        assert(x == 5);
        vm.stopBroadcast();
    }
}
