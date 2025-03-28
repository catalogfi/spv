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

    VerifySPV verifySPV = VerifySPV(address(0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82));

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/blockheader.json");
        string memory json = vm.readFile(path);

        // Parse fields individually with proper types
        // uint256 length = stdJson.readUint(json, ".length");

        for (uint256 i = 1; i < 7; i++) {
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
        verifySPV.registerLatestBlock(difficultyEpoch, 5);
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
        bytes32[] memory proof = new bytes32[](5);

        // block 203 
        proof[0] = 0x3c0b0b0c36c9633e098d77703dc80101295ea6ca136b2125b1b2862e63f426fd;
        proof[1] = 0x80d2c687fdc49c573f948718b7c92285198b0eae8ccf601ac20fd84d6657fea9;
        proof[2] = 0xf49e4cbf319e8f5a9df2bca0eceb94904c352a0f7f9c7d35a74aa9ae11c97af6;
        proof[3] = 0xc4c15d54f823ffb4684e40d03ae917b57e6ec433982cbd12780dcc5e9b1ddf96;
        proof[4] = 0xb23d9b2085f89659482050ba1d2c488c9adfb9ea96bf2d788078c65813b2579a;

        // block 202 
        // proof[0] = 0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d;
        // proof[1] = 0x056c7c24fa1354e5a48d451154e22e420aa542867abeaa6b203ece181ccdac52;
        // proof[2] = 0x1ea1d5edcd7e776e16a6e0c523a8be8f5635592e7e4d3cb1a94d04acebe23912;
        // proof[3] = 0xa28c327dede8b27e1e4cc3e0d373bc91361bb7f4370aea686b70d22e9c3605fb;

        uint256 x = verifySPV.verifyTxInclusion(
            difficultyEpoch, 2, 7, 0x442277db570ed285d190b7104e7610526ea44dcee34318eae35eeee97d6dfad1, proof
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
