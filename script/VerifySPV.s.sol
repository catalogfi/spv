// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VerifySPV, BlockHeader, LibBitcoin} from "../src/VerifySPV.sol";
import "forge-std/StdJson.sol";

contract SPVDeploy is Script {
    using stdJson for string;

    BlockHeader[] difficultyEpoch;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 0; i < 1; i++) {
            string memory base = string.concat("[", vm.toString(i), "]");

            BlockHeader memory header;
            header.version = bytes4(stdJson.readBytes(json, string.concat(base, ".version")));
            header.previousBlockHash = stdJson.readBytes32(json, string.concat(base, ".previousblockhash"));
            header.merkleRootHash = stdJson.readBytes32(json, string.concat(base, ".merkleroot"));
            header.timestamp = bytes4(stdJson.readBytes(json, string.concat(base, ".time")));
            header.nBits = bytes4(stdJson.readBytes(json, string.concat(base, ".bits")));
            header.nonce = bytes4(stdJson.readBytes(json, string.concat(base, ".nonce")));

            difficultyEpoch.push(header);
        }

        console.log("Loaded %d block headers", difficultyEpoch.length);

        new VerifySPV(difficultyEpoch[0], 0, 1, true);

        vm.stopBroadcast();
    }
}
