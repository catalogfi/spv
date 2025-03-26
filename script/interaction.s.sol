pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VerifySPV, BlockHeader, LibBitcoin} from "../src/VerifySPV.sol";
import {LibSPV} from "../src/libraries/LibSPV.sol";
import "forge-std/StdJson.sol";

contract SPVInteraction is Script {
    using stdJson for string;

    BlockHeader[] difficultyEpoch;

    VerifySPV verifySPV =
        VerifySPV(address(0x0B306BF915C4d645ff596e518fAf3F9669b97016));

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 1; i < 8; i++) {
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
        verifySPV.registerLatestBlock(difficultyEpoch, 6);
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
        proof[0] = 0xbee705c560dad3adc2482075c076fc05d04c64ab0f27632ce827d7706c53d1cb;

        verifySPV.verifyTxInclusion(difficultyEpoch, 1,0, 0xfb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38, proof);
        vm.stopBroadcast();
    }
}
