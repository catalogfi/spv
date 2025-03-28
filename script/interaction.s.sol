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

    VerifySPV verifySPV = VerifySPV(address(0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44));

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

        proof[0] = 0xc308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e;
        proof[1] = 0x94b6c7d8a232f5ec7e4d39bce0d6c134bc789be99b154d9a5cae0fabd22e0b20;
        proof[2] = 0x14feb8179061d42d350abf2a009176d82bcc5f32a84ed4a9c0165dde0e4285bb;
        proof[3] = 0xa28c327dede8b27e1e4cc3e0d373bc91361bb7f4370aea686b70d22e9c3605fb;

        uint256 x = verifySPV.verifyTxInclusion(
            difficultyEpoch, 1, 0, 0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b, proof
        );
        console.logUint(x);
        // assert(x == 5);
        vm.stopBroadcast();
    }
}
