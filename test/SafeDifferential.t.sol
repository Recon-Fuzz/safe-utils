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

    function test_Safe_multiSendConfig_matchesSafeDeployments() public {
        (uint256[] memory chainIds, uint256[] memory counts, address[] memory addresses) =
            _readSafeDeploymentsMultiSendConfig();

        assertEq(chainIds.length, counts.length);

        uint256 cursor;
        for (uint256 i = 0; i < chainIds.length; i++) {
            address resolved = address(safe.getMultiSendCallOnly(chainIds[i]));
            bool found;

            for (uint256 j = 0; j < counts[i]; j++) {
                if (resolved == addresses[cursor + j]) {
                    found = true;
                    break;
                }
            }

            assertTrue(found, string.concat("unexpected multisend address for chain ", vm.toString(chainIds[i])));
            cursor += counts[i];
        }

        assertEq(cursor, addresses.length);
    }

    function _readTypeScriptSdkConfig() private returns (uint256[] memory chainIds, string[] memory urls) {
        string[] memory inputs = new string[](2);
        inputs[0] = "node";
        inputs[1] = "test/ffi/safe-api-kit-config.cjs";

        string memory json = string(vm.ffi(inputs));
        chainIds = json.readUintArray(".chainIds");
        urls = json.readStringArray(".urls");
    }

    function _readSafeDeploymentsMultiSendConfig()
        private
        returns (uint256[] memory chainIds, uint256[] memory counts, address[] memory addresses)
    {
        string[] memory inputs = new string[](2);
        inputs[0] = "node";
        inputs[1] = "test/ffi/safe-multisend-config.cjs";

        string memory json = string(vm.ffi(inputs));
        chainIds = json.readUintArray(".chainIds");
        counts = json.readUintArray(".counts");
        addresses = json.readAddressArray(".addresses");
    }
}
