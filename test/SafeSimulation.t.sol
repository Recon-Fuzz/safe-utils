// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

interface ISafeOwnerManager {
    function changeThreshold(uint256 _threshold) external;
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
}

/// @notice Tests for Safe.sol simulation functions.
///
///         The Safe at SAFE_ADDRESS is a test Safe on Base whose owners are the
///         three default Foundry test accounts, so no private keys are needed
///         for signature-based tests and no storage hacks are needed for
///         simulation tests (the signers are already legitimate owners).
contract SafeSimulationTest is Test {
    using Safe for *;

    Safe.Client safe;

    address constant SAFE_ADDRESS = 0xF3a292Dda3F524EA20b5faF2EE0A1c4abA665e4F;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    // Owners of SAFE_ADDRESS — foundry default accounts (threshold=2 on-chain)
    address constant SIGNER_1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant SIGNER_2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    bytes32 constant SIGNER_1_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function setUp() public {
        vm.setEnv("SAFE_BROADCAST", "false"); // reset any env bleed from prior tests
        vm.createSelectFork("https://mainnet.base.org");
        safe.initialize(SAFE_ADDRESS);
        // Lower threshold to 1 so single-signer simulation tests work.
        // Each test gets a fresh fork snapshot so this does not affect other suites.
        vm.prank(SAFE_ADDRESS);
        ISafeOwnerManager(SAFE_ADDRESS).changeThreshold(1);
    }

    // -------------------------------------------------------------------------
    // Mode detection
    // -------------------------------------------------------------------------

    function test_Safe_modeDetection() public {
        vm.setEnv("SAFE_BROADCAST", "false");
        assertTrue(Safe.isSimulationMode());
        assertFalse(Safe.isBroadcastMode());

        vm.setEnv("SAFE_BROADCAST", "true");
        assertTrue(Safe.isBroadcastMode());
        assertFalse(Safe.isSimulationMode());

        vm.setEnv("SAFE_BROADCAST", "false");
        assertFalse(Safe.isBroadcastMode());
        assertTrue(Safe.isSimulationMode());
    }

    // -------------------------------------------------------------------------
    // Single-signer simulation
    // -------------------------------------------------------------------------

    function test_Safe_simulateTransactionNoSign_succeeds() public {
        // WETH withdraw(0) is a no-op that always succeeds regardless of balance
        bool ok = safe.simulateTransactionNoSign(WETH, abi.encodeCall(IWETH.withdraw, (0)), SIGNER_1);
        assertTrue(ok);
    }

    function test_Safe_simulateTransactionNoSign_returnsFalseOnRevert() public {
        // Safe has no WETH, so withdraw(1) reverts — execTransaction returns false
        bool ok = safe.simulateTransactionNoSign(WETH, abi.encodeCall(IWETH.withdraw, (1)), SIGNER_1);
        assertFalse(ok);
    }

    function test_Safe_simulateTransactionNoSign_nonceAdvances() public {
        uint256 nonceBefore = safe.getNonce();
        safe.simulateTransactionNoSign(WETH, abi.encodeCall(IWETH.withdraw, (0)), SIGNER_1);
        assertEq(safe.getNonce(), nonceBefore + 1);
    }

    // -------------------------------------------------------------------------
    // Batch simulation
    // -------------------------------------------------------------------------

    function test_Safe_simulateTransactionsNoSign_succeeds() public {
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));
        targets[1] = WETH;
        datas[1] = abi.encodeCall(IWETH.withdraw, (0));

        bool ok = safe.simulateTransactionsNoSign(targets, datas, SIGNER_1);
        assertTrue(ok);
    }

    function test_Safe_simulateTransactionsNoSign_returnsFalseOnRevert() public {
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));
        targets[1] = WETH;
        datas[1] = abi.encodeCall(IWETH.withdraw, (1)); // fails — no WETH balance

        bool ok = safe.simulateTransactionsNoSign(targets, datas, SIGNER_1);
        assertFalse(ok);
    }

    // -------------------------------------------------------------------------
    // Multi-sig simulation
    // -------------------------------------------------------------------------

    function test_Safe_simulateTransactionMultiSigNoSign_succeeds() public {
        vm.prank(SAFE_ADDRESS);
        ISafeOwnerManager(SAFE_ADDRESS).changeThreshold(2);

        address[] memory signers = new address[](2);
        signers[0] = SIGNER_1;
        signers[1] = SIGNER_2;

        bool ok = safe.simulateTransactionMultiSigNoSign(WETH, abi.encodeCall(IWETH.withdraw, (0)), signers);
        assertTrue(ok);
    }

    function test_Safe_simulateTransactionMultiSigNoSign_returnsFalseWithInsufficientSigners() public {
        // threshold=2 but only 1 signer provided — Safe's checkNSignatures should reject
        vm.prank(SAFE_ADDRESS);
        ISafeOwnerManager(SAFE_ADDRESS).changeThreshold(2);

        address[] memory signers = new address[](1);
        signers[0] = SIGNER_1;

        bool ok = safe.simulateTransactionMultiSigNoSign(WETH, abi.encodeCall(IWETH.withdraw, (0)), signers);
        assertFalse(ok);
    }

    function test_Safe_simulateTransactionsMultiSigNoSign_succeeds() public {
        vm.prank(SAFE_ADDRESS);
        ISafeOwnerManager(SAFE_ADDRESS).changeThreshold(2);

        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));
        targets[1] = WETH;
        datas[1] = abi.encodeCall(IWETH.withdraw, (0));

        address[] memory signers = new address[](2);
        signers[0] = SIGNER_1;
        signers[1] = SIGNER_2;

        bool ok = safe.simulateTransactionsMultiSigNoSign(targets, datas, signers);
        assertTrue(ok);
    }

    // -------------------------------------------------------------------------
    // Nonce overloads
    // -------------------------------------------------------------------------

    function test_Safe_sign_explicitNonce_isUsedInSignature() public {
        // Signing the same payload with different nonces must produce different signatures.
        // This proves the explicit-nonce overload threads the nonce through to the
        // SafeTx hash that gets signed (rather than silently using getNonce()).
        vm.rememberKey(uint256(SIGNER_1_KEY));
        bytes memory data = abi.encodeCall(IWETH.withdraw, (0));

        bytes memory sigA = safe.sign(WETH, data, Enum.Operation.Call, SIGNER_1, 100, "");
        bytes memory sigB = safe.sign(WETH, data, Enum.Operation.Call, SIGNER_1, 101, "");

        assertGt(sigA.length, 0);
        assertGt(sigB.length, 0);
        assertTrue(keccak256(sigA) != keccak256(sigB));
    }

    function test_Safe_sign_explicitNonce_batchOperation() public {
        // Same check for the DelegateCall path used by batch proposes.
        vm.rememberKey(uint256(SIGNER_1_KEY));

        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));
        targets[1] = WETH;
        datas[1] = abi.encodeCall(IWETH.withdraw, (0));

        (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
        bytes memory sigA = safe.sign(to, data, Enum.Operation.DelegateCall, SIGNER_1, 100, "");
        bytes memory sigB = safe.sign(to, data, Enum.Operation.DelegateCall, SIGNER_1, 101, "");

        assertGt(sigA.length, 0);
        assertGt(sigB.length, 0);
        assertTrue(keccak256(sigA) != keccak256(sigB));
    }
}
