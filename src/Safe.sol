// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {HTTP} from "solidity-http/HTTP.sol";
import {MultiSendCallOnly} from "safe-smart-account/libraries/MultiSendCallOnly.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";
import {ISafeSmartAccount} from "./ISafeSmartAccount.sol";

library Safe {
    using HTTP for *;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // https://github.com/safe-global/safe-smart-account/blob/release/v1.4.1/contracts/libraries/SafeStorage.sol
    bytes32 constant SAFE_THRESHOLD_STORAGE_SLOT = bytes32(uint256(4));

    // https://github.com/safe-global/safe-deployments/blob/v1.37.32/src/assets/v1.3.0/multi_send_call_only.json
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_EIP155 = 0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_ZKSYNC = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;

    error ApiKitUrlNotFound(uint256 chainId);
    error MultiSendCallOnlyNotFound(uint256 chainId);
    error ArrayLengthsMismatch(uint256 a, uint256 b);
    error ProposeTransactionFailed(uint256 statusCode, string response);

    struct Instance {
        address safe;
        HTTP.Client http;
        mapping(uint256 chainId => string) urls;
        mapping(uint256 chainId => MultiSendCallOnly) multiSendCallOnly;
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
        // https://github.com/safe-global/safe-core-sdk/blob/r60/packages/api-kit/src/utils/config.ts
        i.urls[1] = "https://safe-transaction-mainnet.safe.global/api";
        i.urls[10] = "https://safe-transaction-optimism.safe.global/api";
        i.urls[56] = "https://safe-transaction-bsc.safe.global/api";
        i.urls[100] = "https://safe-transaction-gnosis-chain.safe.global/api";
        i.urls[130] = "https://safe-transaction-unichain.safe.global/api";
        i.urls[137] = "https://safe-transaction-polygon.safe.global/api";
        i.urls[196] = "https://safe-transaction-xlayer.safe.global/api";
        i.urls[324] = "https://safe-transaction-zksync.safe.global/api";
        i.urls[480] = "https://safe-transaction-worldchain.safe.global/api";
        i.urls[1101] = "https://safe-transaction-zkevm.safe.global/api";
        i.urls[5000] = "https://safe-transaction-mantle.safe.global/api";
        i.urls[8453] = "https://safe-transaction-base.safe.global/api";
        i.urls[42161] = "https://safe-transaction-arbitrum.safe.global/api";
        i.urls[42220] = "https://safe-transaction-celo.safe.global/api";
        i.urls[43114] = "https://safe-transaction-avalanche.safe.global/api";
        i.urls[59144] = "https://safe-transaction-linea.safe.global/api";
        i.urls[81457] = "https://safe-transaction-blast.safe.global/api";
        i.urls[84532] = "https://safe-transaction-base-sepolia.safe.global/api";
        i.urls[534352] = "https://safe-transaction-scroll.safe.global/api";
        i.urls[11155111] = "https://safe-transaction-sepolia.safe.global/api";
        i.urls[1313161554] = "https://safe-transaction-aurora.safe.global/api";

        // https://github.com/safe-global/safe-deployments/blob/v1.37.32/src/assets/v1.3.0/multi_send_call_only.json
        i.multiSendCallOnly[1] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[10] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[56] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[100] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[130] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[137] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[196] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[324] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_ZKSYNC);
        i.multiSendCallOnly[480] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[1101] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[5000] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[8453] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[42161] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[42220] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[43114] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[59144] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[81457] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[84532] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[534352] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[11155111] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);
        i.multiSendCallOnly[1313161554] = MultiSendCallOnly(MULTI_SEND_CALL_ONLY_ADDRESS_CANONICAL);

        i.http.initialize().withHeader("Content-Type", "application/json");
        return self;
    }

    function instance(Client storage self) internal view returns (Instance storage) {
        return self.instances[self.instances.length - 1];
    }

    function getApiKitUrl(Client storage self, uint256 chainId) internal view returns (string memory) {
        string memory url = instance(self).urls[chainId];
        if (bytes(url).length == 0) {
            revert ApiKitUrlNotFound(chainId);
        }
        return url;
    }

    function getMultiSendCallOnly(Client storage self, uint256 chainId) internal view returns (MultiSendCallOnly) {
        MultiSendCallOnly multiSendCallOnly = instance(self).multiSendCallOnly[chainId];
        if (address(multiSendCallOnly) == address(0)) {
            revert MultiSendCallOnlyNotFound(chainId);
        }
        return multiSendCallOnly;
    }

    function getNonce(Client storage self) internal view returns (uint256) {
        return ISafeSmartAccount(instance(self).safe).nonce();
    }

    function getSafeTxHash(
        Client storage self,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 nonce
    ) internal view returns (bytes32) {
        return ISafeSmartAccount(instance(self).safe).getTransactionHash(
            to, value, data, operation, 0, 0, 0, address(0), address(0), nonce
        );
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

        HTTP.Response memory response = instance(self).http.instance().POST(
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
    /// @dev    This can be used to propose transactions signed with a hardware wallet in a two-step process
    ///
    /// @param  self        The Safe client
    /// @param  targets     The list of target addresses for the transactions
    /// @param  datas       The list of data payloads for the transactions
    /// @param  sender      The address of the account that is proposing the transactions
    /// @param  signature   The precomputed signature for the batch of transactions, e.g. using {sign}
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
