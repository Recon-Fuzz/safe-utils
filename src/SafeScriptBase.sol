// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";
import {Safe} from "./Safe.sol";

/// @title SafeScriptBase
/// @notice Base contract for Foundry scripts that interact with a Gnosis Safe.
///         Automatically detects simulation vs broadcast mode and routes
///         transactions accordingly.
///
/// SIMULATION (no --broadcast):
///   forge script MyScript.s.sol --rpc-url $RPC_URL --ffi -vvvv
///   - Executes on a local fork via storage manipulation (no HW wallet needed)
///   - Reveals state changes, reverts, and deployment addresses before broadcasting
///
/// BROADCAST (with --broadcast):
///   forge script MyScript.s.sol --rpc-url $RPC_URL --broadcast --ffi -vvvv
///   - Signs with Ledger/Trezor (set HARDWARE_WALLET=trezor if needed)
///   - Proposes transactions to the Safe Transaction Service API
///
/// ENVIRONMENT VARIABLES:
///   DEPLOYER_SAFE_ADDRESS  - The Safe address
///   SIGNER_ADDRESS         - Owner address for single-signer scripts
///   SIGNER_ADDRESS_0, _1, _2 ... - Owner addresses for multi-sig scripts
///   DERIVATION_PATH        - HW wallet path, e.g. "m/44'/60'/0'/0/0"
///   HARDWARE_WALLET        - "ledger" (default) or "trezor"
abstract contract SafeScriptBase is Script {
    using Safe for *;

    Safe.Client internal safe;
    address internal deployerSafeAddress;

    /// @dev Primary signer for single-sig scripts; index-0 signer in multi-sig scripts.
    address internal signer;

    /// @dev All signers loaded by _initializeSafeMultiSig().
    address[] internal signers;

    string internal derivationPath;

    /// @dev Tracks the nonce for sequential proposes in one script run.
    ///      The Safe's on-chain nonce only advances on execution, so we
    ///      increment this manually after each propose/simulate call.
    uint256 internal currentNonce;

    bool internal _isSimulation;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Initialize for a single-signer Safe. Call from setUp().
    function _initializeSafe() internal {
        deployerSafeAddress = vm.envAddress("DEPLOYER_SAFE_ADDRESS");
        safe.initialize(deployerSafeAddress);
        signer = vm.envAddress("SIGNER_ADDRESS");
        derivationPath = vm.envOr("DERIVATION_PATH", string(""));
        _isSimulation = Safe.isSimulationMode();
        currentNonce = safe.getNonce();
        console.log(
            "[safe-utils] mode: %s | safe: %s | signer: %s",
            _isSimulation ? "simulation" : "broadcast",
            deployerSafeAddress,
            signer
        );
    }

    /// @notice Initialize for a multi-sig Safe. Reads SIGNER_ADDRESS_0, _1, _2 … from env.
    ///         Falls back to SIGNER_ADDRESS if no indexed vars are found.
    function _initializeSafeMultiSig() internal {
        deployerSafeAddress = vm.envAddress("DEPLOYER_SAFE_ADDRESS");
        safe.initialize(deployerSafeAddress);
        uint256 i = 0;
        while (true) {
            address s = vm.envOr(string.concat("SIGNER_ADDRESS_", vm.toString(i)), address(0));
            if (s == address(0)) break;
            signers.push(s);
            i++;
        }
        if (signers.length == 0) {
            signer = vm.envAddress("SIGNER_ADDRESS");
            signers.push(signer);
        } else {
            signer = signers[0];
        }
        derivationPath = vm.envOr("DERIVATION_PATH", string(""));
        _isSimulation = Safe.isSimulationMode();
        currentNonce = safe.getNonce();
        console.log(
            "[safe-utils] mode: %s | safe: %s | signers: %d",
            _isSimulation ? "simulation" : "broadcast",
            deployerSafeAddress,
            signers.length
        );
    }

    // -------------------------------------------------------------------------
    // Transaction helpers
    // -------------------------------------------------------------------------

    /// @notice Simulate or propose a single transaction.
    /// @param  description Human-readable label shown in logs.
    function _proposeTransaction(address target, bytes memory data, string memory description)
        internal
        returns (bytes32)
    {
        console.log("[safe-utils] %s -> %s", description, target);
        if (_isSimulation) {
            bool ok = signers.length > 1
                ? safe.simulateTransactionMultiSigNoSign(target, data, signers)
                : safe.simulateTransactionNoSign(target, data, signer);
            if (!ok) revert(string.concat(description, ": simulation failed"));
            currentNonce++;
            return bytes32(uint256(1));
        } else {
            bytes memory sig = safe.sign(target, data, Enum.Operation.Call, signer, currentNonce, derivationPath);
            bytes32 txHash = safe.proposeTransactionWithSignature(target, data, signer, sig, currentNonce);
            currentNonce++;
            console.log("[safe-utils] proposed safeTxHash: %s", vm.toString(txHash));
            return txHash;
        }
    }

    /// @notice Simulate or propose a single transaction, verifying a contract was deployed at
    ///         expectedDeployment afterward. Skips if code is already present (idempotent).
    function _proposeTransactionWithVerification(
        address target,
        bytes memory data,
        address expectedDeployment,
        string memory description
    ) internal returns (bytes32) {
        if (expectedDeployment.code.length > 0) {
            console.log("[safe-utils] %s: already deployed at %s, skipping", description, expectedDeployment);
            return bytes32(uint256(2));
        }
        bytes32 result = _proposeTransaction(target, data, description);
        if (_isSimulation && expectedDeployment.code.length == 0) {
            revert(string.concat(description, ": no code at expected deployment address after simulation"));
        }
        return result;
    }

    /// @notice Simulate or propose a batch of transactions via MultiSend.
    function _proposeTransactions(address[] memory targets, bytes[] memory datas, string memory description)
        internal
        returns (bytes32)
    {
        console.log("[safe-utils] %s (batch: %d txs)", description, targets.length);
        if (_isSimulation) {
            bool ok = signers.length > 1
                ? safe.simulateTransactionsMultiSigNoSign(targets, datas, signers)
                : safe.simulateTransactionsNoSign(targets, datas, signer);
            if (!ok) revert(string.concat(description, ": batch simulation failed"));
            currentNonce++;
            return bytes32(uint256(1));
        } else {
            (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
            bytes memory sig = safe.sign(to, data, Enum.Operation.DelegateCall, signer, currentNonce, derivationPath);
            bytes32 txHash = safe.proposeTransactionsWithSignature(targets, datas, signer, sig, currentNonce);
            currentNonce++;
            console.log("[safe-utils] proposed safeTxHash: %s", vm.toString(txHash));
            return txHash;
        }
    }

    // -------------------------------------------------------------------------
    // Utility
    // -------------------------------------------------------------------------

    function isSimulation() internal view returns (bool) {
        return _isSimulation;
    }

    function getSafeNonce() internal view returns (uint256) {
        return safe.getNonce();
    }

    function getSafeAddress() internal view returns (address) {
        return deployerSafeAddress;
    }

    function getSigners() internal view returns (address[] memory) {
        return signers;
    }

    function getSignerCount() internal view returns (uint256) {
        return signers.length;
    }

    function isMultiSig() internal view returns (bool) {
        return signers.length > 1;
    }
}
