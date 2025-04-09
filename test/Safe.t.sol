// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {strings} from "../lib/solidity-stringutils/src/strings.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract SafeTest is Test {
    using Safe for *;
    using strings for *;

    Safe.Client safe;
    address safeAddress = 0xF3a292Dda3F524EA20b5faF2EE0A1c4abA665e4F;
    address foundrySigner1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 foundrySigner1PrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org", 28363380);
        safe.initialize(safeAddress);
    }

    function test_Safe_getApiKitUrl() public view {
        string memory url = safe.getApiKitUrl(block.chainid);
        assertGt(bytes(url).length, 0);
    }

    function test_Safe_proposeTransaction() public {
        address weth = 0x4200000000000000000000000000000000000006;
        vm.rememberKey(uint256(foundrySigner1PrivateKey));
        safe.proposeTransaction(weth, abi.encodeCall(IWETH.withdraw, (0)), foundrySigner1);
    }

    function test_Safe_getExecTransactionData() public {
        address weth = 0x4200000000000000000000000000000000000006;
        bytes memory data = safe.getExecTransactionData(weth, abi.encodeCall(IWETH.withdraw, (0)), foundrySigner1, true);
        console.logBytes(data);
    }
}
