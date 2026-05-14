// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {HTTP} from "solidity-http/HTTP.sol";
import {MultiSendCallOnly} from "safe-smart-account/libraries/MultiSendCallOnly.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";
import {ISafeSmartAccount} from "./ISafeSmartAccount.sol";

library Safe {
    using HTTP for *;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
    string constant SAFE_TRANSACTION_SERVICE_BASE_URL = "https://api.safe.global/tx-service";
    string constant PLUME_TRANSACTION_SERVICE_URL = "https://safe-transaction-plume.onchainden.com/api";

    // https://github.com/safe-global/safe-smart-account/blob/release/v1.4.1/contracts/libraries/SafeStorage.sol
    bytes32 constant SAFE_THRESHOLD_STORAGE_SLOT = bytes32(uint256(4));

    // https://github.com/safe-global/safe-deployments/blob/c6a2025fca317b629d73d24b472c266418e2a4d6/src/assets/v1.3.0/multi_send_call_only.json
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V130_ZKSYNC = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;
    // https://github.com/safe-global/safe-deployments/blob/c6a2025fca317b629d73d24b472c266418e2a4d6/src/assets/v1.4.1/multi_send_call_only.json
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V141_ZKSYNC = 0x0408EF011960d02349d50286D20531229BCef773;

    // https://github.com/safe-global/safe-smart-account/blob/release/v1.4.1/contracts/libraries/SafeStorage.sol
    uint256 constant SAFE_APPROVED_HASHES_SLOT = 8;

    error ApiKitUrlNotFound(uint256 chainId);
    error MultiSendCallOnlyNotFound(uint256 chainId);
    error ArrayLengthsMismatch(uint256 a, uint256 b);
    error ProposeTransactionFailed(uint256 statusCode, string response);

    struct Instance {
        address safe;
        HTTP.Client http;
        string requestBody;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Client {
        Instance[] instances;
    }

    struct ExecTransactionParams {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        address sender;
        bytes signature;
        uint256 nonce;
    }

    function initialize(Client storage self, address safe) internal returns (Client storage) {
        self.instances.push();
        Instance storage i = self.instances[self.instances.length - 1];
        i.safe = safe;
        i.http.initialize().withHeader("Content-Type", "application/json").withFollowRedirects(true);
        return self;
    }

    function instance(Client storage self) internal view returns (Instance storage) {
        return self.instances[self.instances.length - 1];
    }

    // Keep the first Client parameter so existing `using Safe for *` call sites remain unchanged.
    function getApiKitUrl(Client storage, uint256 chainId) internal pure returns (string memory) {
        if (chainId == 98866) {
            return PLUME_TRANSACTION_SERVICE_URL;
        }
        return getTransactionServiceUrl(chainId);
    }

    // Mirrors safe-global/safe-core-sdk/packages/api-kit/src/utils/config.ts on main.
    function getNetworkShortName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "eth";
        if (chainId == 10) return "oeth";
        if (chainId == 50) return "xdc";
        if (chainId == 56) return "bnb";
        if (chainId == 100) return "gno";
        if (chainId == 130) return "unichain";
        if (chainId == 137) return "pol";
        if (chainId == 143) return "monad";
        if (chainId == 146) return "sonic";
        if (chainId == 196) return "okb";
        if (chainId == 204) return "opbnb";
        if (chainId == 232) return "lens";
        if (chainId == 324) return "zksync";
        if (chainId == 480) return "wc";
        if (chainId == 988) return "stable";
        if (chainId == 999) return "hyper";
        if (chainId == 1101) return "zkevm";
        if (chainId == 3338) return "peaq";
        if (chainId == 3637) return "btc";
        if (chainId == 5000) return "mantle";
        if (chainId == 8453) return "base";
        if (chainId == 9745) return "plasma";
        if (chainId == 10143) return "monad-testnet";
        if (chainId == 10200) return "chi";
        if (chainId == 16661) return "0g";
        if (chainId == 42161) return "arb1";
        if (chainId == 42220) return "celo";
        if (chainId == 43111) return "hemi";
        if (chainId == 43114) return "avax";
        if (chainId == 57073) return "ink";
        if (chainId == 59144) return "linea";
        if (chainId == 80069) return "bep";
        if (chainId == 80094) return "berachain";
        if (chainId == 81224) return "codex";
        if (chainId == 84532) return "basesep";
        if (chainId == 534352) return "scr";
        if (chainId == 747474) return "katana";
        if (chainId == 11155111) return "sep";
        if (chainId == 1313161554) return "aurora";
        revert ApiKitUrlNotFound(chainId);
    }

    function getTransactionServiceUrl(uint256 chainId) internal pure returns (string memory) {
        return string.concat(SAFE_TRANSACTION_SERVICE_BASE_URL, "/", getNetworkShortName(chainId), "/api");
    }

    // Keep the first Client parameter so existing `using Safe for *` call sites remain unchanged.
    function getMultiSendCallOnly(Client storage, uint256 chainId) internal pure returns (MultiSendCallOnly) {
        if (chainId == 98866) {
            return MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        }
        if (chainId == 324) {
            return MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_V130_ZKSYNC);
        }
        // safe-deployments registers Lens against the zkSync deployment in both v1.3.0 and v1.4.1.
        if (chainId == 232) {
            return MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_V141_ZKSYNC);
        }
        if (_usesV141CanonicalMultiSend(chainId)) {
            return MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        }
        if (_usesV130CanonicalMultiSend(chainId)) {
            return MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        }
        revert MultiSendCallOnlyNotFound(chainId);
    }

    function _usesV130CanonicalMultiSend(uint256 chainId) private pure returns (bool) {
        return (chainId == 1 || chainId == 10 || chainId == 56 || chainId == 100 || chainId == 130 || chainId == 137
                || chainId == 196 || chainId == 480 || chainId == 999 || chainId == 1101 || chainId == 5000
                || chainId == 8453 || chainId == 10200 || chainId == 42161 || chainId == 42220 || chainId == 43114
                || chainId == 59144 || chainId == 84532 || chainId == 534352 || chainId == 11155111
                || chainId == 1313161554);
    }

    function _usesV141CanonicalMultiSend(uint256 chainId) private pure returns (bool) {
        return (chainId == 50 || chainId == 143 || chainId == 146 || chainId == 204 || chainId == 988 || chainId == 3338
                || chainId == 3637 || chainId == 9745 || chainId == 10143 || chainId == 16661 || chainId == 43111
                || chainId == 57073 || chainId == 80069 || chainId == 80094 || chainId == 81224 || chainId == 747474);
    }

    function getNonce(Client storage self) internal view returns (uint256) {
        return ISafeSmartAccount(instance(self).safe).nonce();
    }

    /// @notice Returns true when the script is running with --broadcast
    /// @dev    SAFE_BROADCAST env var takes precedence, useful for testing or
    ///         environments where vm.isContext is unavailable.
    function isBroadcastMode() internal view returns (bool) {
        if (vm.envOr("SAFE_BROADCAST", false)) return true;
        try vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) returns (bool isBroadcast) {
            return isBroadcast;
        } catch {
            return false;
        }
    }

    /// @notice Returns true when the script is running without --broadcast (dry-run / simulation)
    function isSimulationMode() internal view returns (bool) {
        return !isBroadcastMode();
    }

    function getSafeTxHash(
        Client storage self,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 nonce
    ) internal view returns (bytes32) {
        return ISafeSmartAccount(instance(self).safe)
            .getTransactionHash(to, value, data, operation, 0, 0, 0, address(0), address(0), nonce);
    }

    // =========================================================================
    // Simulation
    // =========================================================================

    /// @notice Execute a pre-built transaction against the Safe on a local fork
    /// @dev    Caller is responsible for setting params.signature before calling.
    ///         Use simulateTransactionNoSign for the common case where no real
    ///         signature is needed.
    function simulateTransaction(Client storage self, ExecTransactionParams memory params) internal returns (bool) {
        address safeAddress = instance(self).safe;
        console.log("[safe-utils] simulating to %s (nonce %d)", params.to, params.nonce);
        /// forge-lint: disable-next-line(unsafe-cheatcode)
        vm.prank(params.sender);
        try ISafeSmartAccount(safeAddress)
            .execTransaction(
                params.to,
                params.value,
                params.data,
                params.operation,
                0,
                0,
                0,
                address(0),
                payable(0),
                params.signature
            ) returns (
            bool ok
        ) {
            if (ok) {
                console.log("[safe-utils] simulation succeeded");
                return true;
            }
            console.log("[safe-utils] simulation failed: execTransaction returned false");
            return false;
        } catch (bytes memory revertData) {
            console.log("[safe-utils] simulation reverted");
            if (revertData.length > 0) {
                console.logBytes(revertData);
            }
            return false;
        }
    }

    /// @notice Simulate a single Call transaction without a hardware wallet
    /// @dev    Writes 1 to approvedHashes[sender][txHash] via vm.store so the Safe
    ///         accepts the synthetic approved-hash signature (r=sender, s=0, v=1).
    function simulateTransactionNoSign(Client storage self, address to, bytes memory data, address sender)
        internal
        returns (bool)
    {
        return simulateTransactionNoSign(self, to, data, Enum.Operation.Call, sender);
    }

    /// @notice Simulate a transaction without a hardware wallet, with explicit operation type
    function simulateTransactionNoSign(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender
    ) internal returns (bool) {
        uint256 nonce = getNonce(self);
        address safeAddress = instance(self).safe;
        bytes32 txHash = getSafeTxHash(self, to, 0, data, operation, nonce);
        bytes32 ownerSlot = keccak256(abi.encode(sender, SAFE_APPROVED_HASHES_SLOT));
        bytes32 approvalSlot = keccak256(abi.encode(txHash, ownerSlot));
        /// forge-lint: disable-next-line(unsafe-cheatcode)
        vm.store(safeAddress, approvalSlot, bytes32(uint256(1)));
        // Approved-hash signature format: r=owner (padded), s=0, v=1
        bytes memory signature = abi.encodePacked(bytes32(uint256(uint160(sender))), bytes32(0), uint8(1));
        return simulateTransaction(
            self,
            ExecTransactionParams({
                to: to, value: 0, data: data, operation: operation, sender: sender, signature: signature, nonce: nonce
            })
        );
    }

    /// @notice Simulate a batch of transactions via MultiSend without a hardware wallet
    function simulateTransactionsNoSign(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender
    ) internal returns (bool) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        uint256 nonce = getNonce(self);
        address safeAddress = instance(self).safe;
        bytes32 txHash = getSafeTxHash(self, to, 0, data, Enum.Operation.DelegateCall, nonce);
        bytes32 ownerSlot = keccak256(abi.encode(sender, SAFE_APPROVED_HASHES_SLOT));
        bytes32 approvalSlot = keccak256(abi.encode(txHash, ownerSlot));
        /// forge-lint: disable-next-line(unsafe-cheatcode)
        vm.store(safeAddress, approvalSlot, bytes32(uint256(1)));
        bytes memory signature = abi.encodePacked(bytes32(uint256(uint160(sender))), bytes32(0), uint8(1));
        return simulateTransaction(
            self,
            ExecTransactionParams({
                to: to,
                value: 0,
                data: data,
                operation: Enum.Operation.DelegateCall,
                sender: sender,
                signature: signature,
                nonce: nonce
            })
        );
    }

    /// @notice Simulate a single transaction with a multi-sig Safe (threshold > 1) without hardware wallets
    /// @dev    Signers are sorted ascending as required by Safe's checkNSignatures.
    ///         Provide at least `threshold` addresses — extras are ignored by the Safe.
    function simulateTransactionMultiSigNoSign(
        Client storage self,
        address to,
        bytes memory data,
        address[] memory signers
    ) internal returns (bool) {
        return _simulateMultiSig(self, to, data, Enum.Operation.Call, signers);
    }

    /// @notice Simulate a batch of transactions with a multi-sig Safe without hardware wallets
    function simulateTransactionsMultiSigNoSign(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address[] memory signers
    ) internal returns (bool) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        return _simulateMultiSig(self, to, data, Enum.Operation.DelegateCall, signers);
    }

    function _simulateMultiSig(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address[] memory signers
    ) private returns (bool) {
        uint256 nonce = getNonce(self);
        address safeAddress = instance(self).safe;
        bytes32 txHash = getSafeTxHash(self, to, 0, data, operation, nonce);
        address[] memory sorted = _sortAddresses(signers);
        bytes memory signatures;
        for (uint256 i; i < sorted.length; i++) {
            bytes32 ownerSlot = keccak256(abi.encode(sorted[i], SAFE_APPROVED_HASHES_SLOT));
            bytes32 approvalSlot = keccak256(abi.encode(txHash, ownerSlot));
            /// forge-lint: disable-next-line(unsafe-cheatcode)
            vm.store(safeAddress, approvalSlot, bytes32(uint256(1)));
            signatures = abi.encodePacked(signatures, bytes32(uint256(uint160(sorted[i]))), bytes32(0), uint8(1));
        }
        return simulateTransaction(
            self,
            ExecTransactionParams({
                to: to,
                value: 0,
                data: data,
                operation: operation,
                sender: sorted[0],
                signature: signatures,
                nonce: nonce
            })
        );
    }

    /// @dev Bubble-sort signers ascending. Safe requires signatures ordered by signer address.
    function _sortAddresses(address[] memory arr) private pure returns (address[] memory) {
        uint256 n = arr.length;
        for (uint256 i; i < n; i++) {
            for (uint256 j = i + 1; j < n; j++) {
                if (uint160(arr[i]) > uint160(arr[j])) (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
        return arr;
    }

    // https://github.com/safe-global/safe-core-sdk/blob/r60/packages/api-kit/src/SafeApiKit.ts#L574
    function proposeTransaction(Client storage self, ExecTransactionParams memory params) internal returns (bytes32) {
        bytes32 safeTxHash = getSafeTxHash(self, params.to, params.value, params.data, params.operation, params.nonce);
        instance(self).requestBody = vm.serializeAddress(".proposeTransaction", "to", params.to);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "value", params.value);
        instance(self).requestBody = vm.serializeBytes(".proposeTransaction", "data", params.data);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "operation", uint8(params.operation));
        instance(self).requestBody = vm.serializeBytes32(".proposeTransaction", "contractTransactionHash", safeTxHash);
        instance(self).requestBody = vm.serializeAddress(".proposeTransaction", "sender", params.sender);
        instance(self).requestBody = vm.serializeBytes(".proposeTransaction", "signature", params.signature);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "safeTxGas", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "baseGas", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "gasPrice", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "nonce", params.nonce);

        HTTP.Response memory response = instance(self).http.instance()
            .POST(
                string.concat(
                    getApiKitUrl(self, block.chainid),
                    "/v1/safes/",
                    vm.toString(instance(self).safe),
                    "/multisig-transactions/"
                )
            ).withBody(instance(self).requestBody).request();

        // The response status should be 2xx, otherwise there was an issue
        if (response.status < 200 || response.status >= 300) {
            revert ProposeTransactionFailed(response.status, response.data);
        }

        return safeTxHash;
    }

    function proposeTransaction(Client storage self, address to, bytes memory data, address sender)
        internal
        returns (bytes32)
    {
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.Call, sender, string("")),
            nonce: getNonce(self)
        });
        return proposeTransaction(self, params);
    }

    function proposeTransaction(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        string memory derivationPath
    ) internal returns (bytes32) {
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.Call, sender, derivationPath),
            nonce: getNonce(self)
        });
        return proposeTransaction(self, params);
    }

    /// @notice Propose a transaction with a precomputed signature
    /// @dev    This can be used to propose transactions signed with a hardware wallet in a two-step process
    ///
    /// @param  self        The Safe client
    /// @param  to          The target address for the transaction
    /// @param  data        The data payload for the transaction
    /// @param  sender      The address of the account that is proposing the transaction
    /// @param  signature   The precomputed signature for the transaction, e.g. using {sign}
    /// @return txHash      The hash of the proposed Safe transaction
    function proposeTransactionWithSignature(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        bytes memory signature
    ) internal returns (bytes32 txHash) {
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            sender: sender,
            signature: signature,
            nonce: getNonce(self)
        });
        txHash = proposeTransaction(self, params);
        return txHash;
    }

    /// @notice Propose a transaction with a precomputed signature and an explicit nonce
    /// @dev    Use this when proposing multiple transactions in one script run to avoid
    ///         nonce collisions — the Safe's on-chain nonce only advances on execution,
    ///         so sequential proposes must supply an incrementing nonce manually.
    function proposeTransactionWithSignature(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        bytes memory signature,
        uint256 nonce
    ) internal returns (bytes32 txHash) {
        txHash = proposeTransaction(
            self,
            ExecTransactionParams({
                to: to,
                value: 0,
                data: data,
                operation: Enum.Operation.Call,
                sender: sender,
                signature: signature,
                nonce: nonce
            })
        );
    }

    function getProposeTransactionsTargetAndData(Client storage self, address[] memory targets, bytes[] memory datas)
        internal
        view
        returns (address, bytes memory)
    {
        if (targets.length != datas.length) {
            revert ArrayLengthsMismatch(targets.length, datas.length);
        }
        bytes1 operation = bytes1(uint8(Enum.Operation.Call));
        uint256 value = 0;
        bytes memory transactions;
        for (uint256 i = 0; i < targets.length; i++) {
            uint256 dataLength = datas[i].length;
            transactions =
                abi.encodePacked(transactions, abi.encodePacked(operation, targets[i], value, dataLength, datas[i]));
        }
        address to = address(getMultiSendCallOnly(self, block.chainid));
        bytes memory data = abi.encodeCall(MultiSendCallOnly.multiSend, (transactions));
        return (to, data);
    }

    function proposeTransactions(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender,
        string memory derivationPath
    ) internal returns (bytes32) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        // using DelegateCall to preserve msg.sender across sub-calls
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.DelegateCall, sender, derivationPath),
            nonce: getNonce(self)
        });
        return proposeTransaction(self, params);
    }

    /// @notice Propose multiple transactions with a precomputed signature
    /// @dev    This can be used to propose transactions signed with a hardware wallet in a two-step process.
    ///         The signature must be created with Enum.Operation.DelegateCall, as batch transactions use
    ///         DelegateCall to preserve msg.sender across sub-calls.
    ///
    ///         WARNING: Using Enum.Operation.Call instead of DelegateCall will cause the Safe API to reject
    ///         your transaction with an error about an incorrect signer address. The signature will be invalid
    ///         because it was signed with the wrong operation type.
    ///
    /// @param  self        The Safe client
    /// @param  targets     The list of target addresses for the transactions
    /// @param  datas       The list of data payloads for the transactions
    /// @param  sender      The address of the account that is proposing the transactions
    /// @param  signature   The precomputed signature for the batch of transactions. MUST be signed with
    ///                     Enum.Operation.DelegateCall (use {sign} with DelegateCall operation).
    ///                     Signing with Call instead of DelegateCall will result in signature validation failure.
    /// @return txHash      The hash of the proposed Safe transaction
    function proposeTransactionsWithSignature(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender,
        bytes memory signature
    ) internal returns (bytes32 txHash) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        // using DelegateCall to preserve msg.sender across sub-calls
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            sender: sender,
            signature: signature,
            nonce: getNonce(self)
        });
        txHash = proposeTransaction(self, params);
        return txHash;
    }

    /// @notice Propose multiple transactions with a precomputed signature and an explicit nonce
    /// @dev    Same nonce rationale as proposeTransactionWithSignature(..., nonce).
    function proposeTransactionsWithSignature(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender,
        bytes memory signature,
        uint256 nonce
    ) internal returns (bytes32 txHash) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        txHash = proposeTransaction(
            self,
            ExecTransactionParams({
                to: to,
                value: 0,
                data: data,
                operation: Enum.Operation.DelegateCall,
                sender: sender,
                signature: signature,
                nonce: nonce
            })
        );
    }

    function getExecTransactionData(Client storage self, address to, bytes memory data, address sender)
        internal
        returns (bytes memory)
    {
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.Call, sender, string("")),
            nonce: getNonce(self)
        });
        return getExecTransactionData(self, params);
    }

    function getExecTransactionData(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.Call, sender, derivationPath),
            nonce: getNonce(self)
        });
        return getExecTransactionData(self, params);
    }

    function getExecTransactionsData(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender
    ) internal returns (bytes memory) {
        return getExecTransactionsData(self, targets, datas, sender, string(""));
    }

    function getExecTransactionsData(
        Client storage self,
        address[] memory targets,
        bytes[] memory datas,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        // using DelegateCall to preserve msg.sender across sub-calls
        ExecTransactionParams memory params = ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            sender: sender,
            signature: sign(self, to, data, Enum.Operation.DelegateCall, sender, derivationPath),
            nonce: getNonce(self)
        });
        return getExecTransactionData(self, params);
    }

    function getExecTransactionData(Client storage, ExecTransactionParams memory params)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            ISafeSmartAccount.execTransaction,
            (params.to, 0, params.data, params.operation, 0, 0, 0, address(0), payable(0), params.signature)
        );
    }

    /// @notice Prepare the signature for a transaction, using a custom nonce
    ///
    /// @param  self            The Safe client
    /// @param  to              The target address for the transaction
    /// @param  data            The data payload for the transaction
    /// @param  operation       The operation to perform
    /// @param  sender          The address of the account that is signing the transaction
    /// @param  nonce           The nonce of the transaction
    /// @param  derivationPath  The derivation path for the transaction
    /// @return signature       The signature for the transaction
    function sign(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        uint256 nonce,
        string memory derivationPath
    ) internal returns (bytes memory) {
        if (bytes(derivationPath).length > 0) {
            // Hardware wallet selection via HARDWARE_WALLET env var (defaults to ledger)
            string memory hardwareWallet = vm.envOr("HARDWARE_WALLET", string("ledger"));
            if (keccak256(bytes(hardwareWallet)) == keccak256(bytes("trezor"))) {
                // Trezor signs the raw safeTxHash: `cast wallet sign` does not support
                // EIP-712 --data with --trezor, so we must pass the hash as the message.
                bytes32 safeTxHash = getSafeTxHash(self, to, 0, data, operation, nonce);
                string[] memory trezorInputs = new string[](7);
                trezorInputs[0] = "cast";
                trezorInputs[1] = "wallet";
                trezorInputs[2] = "sign";
                trezorInputs[3] = "--trezor";
                trezorInputs[4] = "--mnemonic-derivation-path";
                trezorInputs[5] = derivationPath;
                trezorInputs[6] = vm.toString(safeTxHash);
                /// forge-lint: disable-next-line(unsafe-cheatcode)
                bytes memory trezorOutput = vm.ffi(trezorInputs);
                // Trezor uses eth_sign, which prepends "\x19Ethereum Signed Message:\n32"
                // to the hash. Safe's checkNSignatures detects this via v >= 31, so add 4.
                trezorOutput[64] = bytes1(uint8(trezorOutput[64]) + 4);
                return trezorOutput;
            }

            string[] memory inputs = new string[](8);
            inputs[0] = "cast";
            inputs[1] = "wallet";
            inputs[2] = "sign";
            inputs[3] = "--ledger";
            inputs[4] = "--mnemonic-derivation-path";
            inputs[5] = derivationPath;
            inputs[6] = "--data";
            inputs[7] = string.concat(
                '{"domain":{"chainId":"',
                vm.toString(block.chainid),
                '","verifyingContract":"',
                vm.toString(instance(self).safe),
                '"},"message":{"to":"',
                vm.toString(to),
                '","value":"0","data":"',
                vm.toString(data),
                '","operation":',
                vm.toString(uint8(operation)),
                ',"baseGas":"0","gasPrice":"0","gasToken":"0x0000000000000000000000000000000000000000","refundReceiver":"0x0000000000000000000000000000000000000000","nonce":',
                vm.toString(nonce),
                ',"safeTxGas":"0"},"primaryType":"SafeTx","types":{"SafeTx":[{"name":"to","type":"address"},{"name":"value","type":"uint256"},{"name":"data","type":"bytes"},{"name":"operation","type":"uint8"},{"name":"safeTxGas","type":"uint256"},{"name":"baseGas","type":"uint256"},{"name":"gasPrice","type":"uint256"},{"name":"gasToken","type":"address"},{"name":"refundReceiver","type":"address"},{"name":"nonce","type":"uint256"}]}}'
            );
            /// forge-lint: disable-next-line(unsafe-cheatcode)
            bytes memory output = vm.ffi(inputs);
            return output;
        } else {
            Signature memory sig;
            (sig.v, sig.r, sig.s) = vm.sign(sender, getSafeTxHash(self, to, 0, data, operation, nonce));
            return abi.encodePacked(sig.r, sig.s, sig.v);
        }
    }

    /// @notice Prepare the signature for a transaction, using the nonce from the Safe
    function sign(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        return sign(self, to, data, operation, sender, getNonce(self), derivationPath);
    }
}
