// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

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
        _assertOfficialTransactionServiceUrl(1, "eth");
        _assertOfficialTransactionServiceUrl(10, "oeth");
        _assertOfficialTransactionServiceUrl(50, "xdc");
        _assertOfficialTransactionServiceUrl(56, "bnb");
        _assertOfficialTransactionServiceUrl(100, "gno");
        _assertOfficialTransactionServiceUrl(130, "unichain");
        _assertOfficialTransactionServiceUrl(137, "pol");
        _assertOfficialTransactionServiceUrl(143, "monad");
        _assertOfficialTransactionServiceUrl(146, "sonic");
        _assertOfficialTransactionServiceUrl(196, "okb");
        _assertOfficialTransactionServiceUrl(204, "opbnb");
        _assertOfficialTransactionServiceUrl(232, "lens");
        _assertOfficialTransactionServiceUrl(324, "zksync");
        _assertOfficialTransactionServiceUrl(480, "wc");
        _assertOfficialTransactionServiceUrl(988, "stable");
        _assertOfficialTransactionServiceUrl(999, "hyper");
        _assertOfficialTransactionServiceUrl(1101, "zkevm");
        _assertOfficialTransactionServiceUrl(3338, "peaq");
        _assertOfficialTransactionServiceUrl(3637, "btc");
        _assertOfficialTransactionServiceUrl(5000, "mantle");
        _assertOfficialTransactionServiceUrl(8453, "base");
        _assertOfficialTransactionServiceUrl(9745, "plasma");
        _assertOfficialTransactionServiceUrl(10143, "monad-testnet");
        _assertOfficialTransactionServiceUrl(10200, "chi");
        _assertOfficialTransactionServiceUrl(16661, "0g");
        _assertOfficialTransactionServiceUrl(42161, "arb1");
        _assertOfficialTransactionServiceUrl(42220, "celo");
        _assertOfficialTransactionServiceUrl(43111, "hemi");
        _assertOfficialTransactionServiceUrl(43114, "avax");
        _assertOfficialTransactionServiceUrl(57073, "ink");
        _assertOfficialTransactionServiceUrl(59144, "linea");
        _assertOfficialTransactionServiceUrl(80069, "bep");
        _assertOfficialTransactionServiceUrl(80094, "berachain");
        _assertOfficialTransactionServiceUrl(81224, "codex");
        _assertOfficialTransactionServiceUrl(84532, "basesep");
        _assertOfficialTransactionServiceUrl(534352, "scr");
        _assertOfficialTransactionServiceUrl(747474, "katana");
        _assertOfficialTransactionServiceUrl(11155111, "sep");
        _assertOfficialTransactionServiceUrl(1313161554, "aurora");
    }

    function test_Safe_getApiKitUrl_prefersThirdPartyOverrides() public view {
        assertEq(safe.getApiKitUrl(98866), "https://safe-transaction-plume.onchainden.com/api");
    }

    function test_Safe_getApiKitUrl_revertsForUnknownChain() public {
        vm.expectRevert(abi.encodeWithSelector(Safe.ApiKitUrlNotFound.selector, 31337));
        this.exposedGetApiKitUrl(31337);
    }

    function test_Safe_getMultiSendCallOnly_resolvesLegacyAndNewDeployments() public view {
        assertEq(address(safe.getMultiSendCallOnly(1)), 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
        assertEq(address(safe.getMultiSendCallOnly(324)), 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F);
        assertEq(address(safe.getMultiSendCallOnly(232)), 0x0408EF011960d02349d50286D20531229BCef773);
        assertEq(address(safe.getMultiSendCallOnly(10143)), 0x9641d764fc13c8B624c04430C7356C1C7C8102e2);
        assertEq(address(safe.getMultiSendCallOnly(98866)), 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
    }

    function test_Safe_getMultiSendCallOnly_revertsForUnknownChain() public {
        vm.expectRevert(abi.encodeWithSelector(Safe.MultiSendCallOnlyNotFound.selector, 31337));
        this.exposedGetMultiSendCallOnly(31337);
    }

    function _assertOfficialTransactionServiceUrl(uint256 chainId, string memory shortName) private pure {
        assertEq(
            Safe.getTransactionServiceUrl(chainId),
            string.concat(SAFE_TRANSACTION_SERVICE_BASE_URL, "/", shortName, "/api")
        );
    }

    function exposedGetApiKitUrl(uint256 chainId) external view returns (string memory) {
        return safe.getApiKitUrl(chainId);
    }

    function exposedGetMultiSendCallOnly(uint256 chainId) external view returns (address) {
        return address(safe.getMultiSendCallOnly(chainId));
    }
}
