// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Safe} from "../src/Safe.sol";
import {SafeConfigFixtures} from "./helpers/SafeConfigFixtures.sol";

contract SafeDifferentialTest is Test {
    using Safe for *;
    using stdJson for string;

    Safe.Client safe;

    function setUp() public {
        safe.initialize(address(0xBEEF));
    }

    function test_Safe_transactionServiceConfig_matchesTypeScriptSdk() public {
        (uint256[] memory expectedChainIds,) = SafeConfigFixtures.officialChains();
        (uint256[] memory chainIds, string[] memory urls) = _readTypeScriptSdkConfig();

        assertEq(chainIds.length, urls.length);
        assertEq(chainIds.length, expectedChainIds.length);

        for (uint256 i = 0; i < chainIds.length; i++) {
            assertEq(chainIds[i], expectedChainIds[i]);
            assertEq(Safe.getTransactionServiceUrl(chainIds[i]), urls[i]);
            assertEq(safe.getApiKitUrl(chainIds[i]), urls[i]);
        }
    }

    function _readTypeScriptSdkConfig() private returns (uint256[] memory chainIds, string[] memory urls) {
        string[] memory inputs = new string[](2);
        inputs[0] = "node";
        inputs[1] = "test/ffi/safe-api-kit-config.cjs";

        string memory json = string(vm.ffi(inputs));
        chainIds = json.readUintArray(".chainIds");
        urls = json.readStringArray(".urls");
    }
}
