// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BlockHeader, LibBitcoin} from "../src/libraries/LibBitcoin.sol";
import {Test} from "forge-std/Test.sol";

contract TestSPV is Test {
    function test_bytesToUint256conversion() public pure {
        bytes memory data = hex"000000000000000000000000000000000000000000000000ffffffffffffffff";
        uint256 result = LibBitcoin.bytesToUint256(data);
        assert(result == 18446744073709551615);
    }
}
