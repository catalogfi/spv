// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {VerifySPV, BlockHeader, LibBitcoin} from "../src/VerifySPV.sol";

contract SPVDeploy is Script {
    function run(bytes calldata _genesisHeader, uint256 _height, uint256 _minConfidence, bool _isTestnet) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // BlockHeader memory genesisHeader = LibBitcoin.parseBlockHeader(_genesisHeader);
        BlockHeader memory genesisHeader = LibBitcoin.parseBlockHeader(_genesisHeader);
        
        VerifySPV spv = new VerifySPV(genesisHeader, _height, _minConfidence, _isTestnet);

        vm.stopBroadcast();
    }
}