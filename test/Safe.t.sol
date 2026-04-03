// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";
import {SafeConfigFixtures} from "./helpers/SafeConfigFixtures.sol";

contract SafeTest is Test {
    using Safe for *;

    Safe.Client safe;
    address safeAddress = 0xF3a292Dda3F524EA20b5faF2EE0A1c4abA665e4F;
    address foundrySigner1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 foundrySigner1PrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function setUp() public {
        // Note: this was previously set to 28363380, but as the Safe API does not
        // operate on a specific block, it was throwing an error about the nonce being used already.
        vm.createSelectFork("https://mainnet.base.org");
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
        vm.rememberKey(uint256(foundrySigner1PrivateKey));
        bytes memory data = safe.getExecTransactionData(weth, abi.encodeCall(IWETH.withdraw, (0)), foundrySigner1, "");
        console.logBytes(data);
    }

    function test_Safe_proposeTransactionsWithSignature() public {
        address weth = 0x4200000000000000000000000000000000000006;

        // Create batch of transactions
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);

        targets[0] = weth;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));

        targets[1] = weth;
        datas[1] = abi.encodeCall(IWETH.withdraw, (1));

        // Get the target and data for signing
        (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);

        // Sign with DelegateCall operation (required for batch transactions)
        vm.rememberKey(uint256(foundrySigner1PrivateKey));
        bytes memory signature = safe.sign(to, data, Enum.Operation.DelegateCall, foundrySigner1, "");

        // Propose transactions with the signature
        safe.proposeTransactionsWithSignature(targets, datas, foundrySigner1, signature);
    }
}

contract SafeConfigTest is Test {
    using Safe for *;

    string constant SAFE_TRANSACTION_SERVICE_BASE_URL = "https://api.safe.global/tx-service";

    Safe.Client safe;

    function setUp() public {
        safe.initialize(address(0xBEEF));
    }

    function test_Safe_getTransactionServiceUrl_matchesLatestOfficialSdkConfig() public pure {
        (uint256[] memory chainIds, string[] memory shortNames) = SafeConfigFixtures.officialChains();

        assertEq(chainIds.length, shortNames.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            assertEq(
                Safe.getTransactionServiceUrl(chainIds[i]),
                string.concat(SAFE_TRANSACTION_SERVICE_BASE_URL, "/", shortNames[i], "/api")
            );
        }
    }

    function test_Safe_getApiKitUrl_prefersThirdPartyOverrides() public view {
        assertEq(safe.getApiKitUrl(98866), "https://safe-transaction-plume.onchainden.com/api");
    }

    function test_Safe_getApiKitUrl_revertsForUnknownChain() public {
        vm.expectRevert(abi.encodeWithSelector(Safe.ApiKitUrlNotFound.selector, 31337));
        this.exposedGetApiKitUrl(31337);
    }

    function test_Safe_getMultiSendCallOnly_resolvesLegacyAndNewDeployments() public view {
        (uint256[] memory chainIds, address[] memory expected) = SafeConfigFixtures.multiSendChains();

        assertEq(chainIds.length, expected.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            assertEq(address(safe.getMultiSendCallOnly(chainIds[i])), expected[i]);
        }
    }

    function test_Safe_getMultiSendCallOnly_revertsForUnknownChain() public {
        vm.expectRevert(abi.encodeWithSelector(Safe.MultiSendCallOnlyNotFound.selector, 31337));
        this.exposedGetMultiSendCallOnly(31337);
    }

    function exposedGetApiKitUrl(uint256 chainId) external view returns (string memory) {
        return safe.getApiKitUrl(chainId);
    }

    function exposedGetMultiSendCallOnly(uint256 chainId) external view returns (address) {
        return address(safe.getMultiSendCallOnly(chainId));
    }
}
