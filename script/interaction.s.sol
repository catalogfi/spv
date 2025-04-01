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

    VerifySPV verifySPV = VerifySPV(address(0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f));

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 1; i < 16; i++) {
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

        // for (uint256 i = 0; i < 17; i++) {
        //     string memory base = string.concat("[", vm.toString(i), "]");

        //     // Create a new BlockHeader
        //     BlockHeader memory header;

        //     // Using toString to ensure we get string values for each field
        //     string memory versionStr = vm.toString(vm.parseJson(json, string.concat(base, ".version")));
        //     string memory timeStr = vm.toString(vm.parseJson(json, string.concat(base, ".time")));
        //     string memory bitsStr = vm.toString(vm.parseJson(json, string.concat(base, ".bits")));
        //     string memory nonceStr = vm.toString(vm.parseJson(json, string.concat(base, ".nonce")));
        //     string memory previousBlockHashStr =
        //         vm.toString(vm.parseJson(json, string.concat(base, ".previousblockhash")));
        //     string memory merkleRootHashStr = vm.toString(vm.parseJson(json, string.concat(base, ".merkleroot")));

        //     // Convert to bytes using parseBytes
        //     header.version = bytes4(vm.parseBytes(versionStr));
        //     header.previousBlockHash = bytes32(vm.parseBytes(previousBlockHashStr));
        //     header.merkleRootHash = bytes32(vm.parseBytes(merkleRootHashStr));
        //     header.timestamp = bytes4(vm.parseBytes(timeStr));
        //     header.nBits = bytes4(vm.parseBytes(bitsStr));
        //     header.nonce = bytes4(vm.parseBytes(nonceStr));

        //     // Add to the array
        //     difficultyEpoch.push(header);
        // }

        // registerBlockAtEnd();
        // insertBlockInBetween();
        checkTrxIncluded();
    }

    function registerBlockAtEnd() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        verifySPV.registerLatestBlock(difficultyEpoch, 14);
        vm.stopBroadcast();
    }

    function insertBlockInBetween() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        verifySPV.registerInclusiveBlock(difficultyEpoch, 9);
        vm.stopBroadcast();
    }

    function checkTrxIncluded() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        bytes32[] memory proof = new bytes32[](4);

        // block 203
        proof[0] = 0x88a22e555edd0ef30339721390995390326a120696e1e56fcd2929680fb025c4;
        proof[1] = 0x749ba3209eac069e5f157f1372ec061ca57594db216fec8b4f0b0ba0109c081f;
        proof[2] = 0xfccad31e25fa1682da5fae8374eb38d51985cf5efa04c9217e845475710feb6e;
        proof[3] = 0x2ee9e104ffa9fde4771e2465177f6ad1aa2eed6e5361601a536262b0d121df88;


        // block 202
        // proof[0] = 0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d;
        // proof[1] = 0x056c7c24fa1354e5a48d451154e22e420aa542867abeaa6b203ece181ccdac52;
        // proof[2] = 0x1ea1d5edcd7e776e16a6e0c523a8be8f5635592e7e4d3cb1a94d04acebe23912;
        // proof[3] = 0xa28c327dede8b27e1e4cc3e0d373bc91361bb7f4370aea686b70d22e9c3605fb;

        uint256 x = verifySPV.verifyTxInclusion(
            difficultyEpoch, 10, 7, 0xeadb0796ecf9ce39f78a983463e184cab3ebda3788c9bc4dc3129e9ae20302ae, proof
        );

        // block 202
        // uint256 x = verifySPV.verifyTxInclusion(
        //     difficultyEpoch, 1, 5, 0x4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a, proof
        // );
        console.logUint(x);
        // assert(x == 5);
        vm.stopBroadcast();
    }
}
