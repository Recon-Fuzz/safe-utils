// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {HTTP} from "../lib/solidity-http/src/HTTP.sol";
import {Safe as SafeSmartAccount} from "../lib/safe-smart-account/contracts/Safe.sol";
import {MultiSendCallOnly} from "../lib/safe-smart-account/contracts/libraries/MultiSendCallOnly.sol";
import {Enum} from "../lib/safe-smart-account/contracts/common/Enum.sol";

library Safe {
    using HTTP for *;

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    error ApiKitUrlNotFound(uint256 chainId);
    error MultiSendCallOnlyNotFound(uint256 chainId);
    error ArrayLengthsMismatch(uint256 a, uint256 b);

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

        i.multiSendCallOnly[1] = MultiSendCallOnly(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
        i.multiSendCallOnly[8453] = MultiSendCallOnly(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
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
        return SafeSmartAccount(payable(instance(self).safe)).nonce();
    }

    function getSafeTxHash(
        Client storage self,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 nonce
    ) internal view returns (bytes32) {
        return SafeSmartAccount(payable(instance(self).safe)).getTransactionHash(
            to, value, data, operation, 0, 0, 0, address(0), address(0), nonce
        );
    }

    // https://github.com/safe-global/safe-core-sdk/blob/r60/packages/api-kit/src/SafeApiKit.ts#L574
    function proposeTransaction(
        Client storage self,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        bytes memory signature,
        uint256 nonce
    ) internal {
        instance(self).requestBody = vm.serializeAddress(".proposeTransaction", "to", to);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "value", value);
        instance(self).requestBody = vm.serializeBytes(".proposeTransaction", "data", data);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "operation", uint8(operation));
        instance(self).requestBody = vm.serializeBytes32(
            ".proposeTransaction", "contractTransactionHash", getSafeTxHash(self, to, value, data, operation, nonce)
        );
        instance(self).requestBody = vm.serializeAddress(".proposeTransaction", "sender", sender);
        instance(self).requestBody = vm.serializeBytes(".proposeTransaction", "signature", signature);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "safeTxGas", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "baseGas", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "gasPrice", 0);
        instance(self).requestBody = vm.serializeUint(".proposeTransaction", "nonce", nonce);

        instance(self).http.instance().POST(
            string.concat(
                getApiKitUrl(self, block.chainid),
                "/v1/safes/",
                vm.toString(instance(self).safe),
                "/multisig-transactions/"
            )
        ).withBody(instance(self).requestBody).request();
    }

    function proposeTransaction(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        bytes memory signature
    ) internal {
        return proposeTransaction(self, to, 0, data, operation, sender, signature, getNonce(self));
    }

    function proposeTransaction(Client storage self, address to, bytes memory data, address sender) internal {
        return proposeTransaction(self, to, data, sender, string(""));
    }

    function proposeTransaction(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        string memory derivationPath
    ) internal {
        bytes memory signature = sign(self, to, data, operation, sender, derivationPath);
        return proposeTransaction(self, to, 0, data, operation, sender, signature, getNonce(self));
    }

    function proposeTransaction(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        string memory derivationPath
    ) internal {
        return proposeTransaction(self, to, data, Enum.Operation.Call, sender, derivationPath);
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
    ) internal {
        (address to, bytes memory data) = getProposeTransactionsTargetAndData(self, targets, datas);
        // using DelegateCall to preserve msg.sender across sub-calls
        return proposeTransaction(self, to, data, Enum.Operation.DelegateCall, sender, derivationPath);
    }

    function getExecTransactionData(Client storage self, address to, bytes memory data, address sender)
        internal
        returns (bytes memory)
    {
        return getExecTransactionData(self, to, data, sender, string(""));
    }

    function getExecTransactionData(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        return getExecTransactionData(self, to, data, Enum.Operation.Call, sender, derivationPath);
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
        return getExecTransactionData(self, to, data, Enum.Operation.DelegateCall, sender, derivationPath);
    }

    function getExecTransactionData(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        bytes memory signature = sign(self, to, data, operation, sender, derivationPath);
        return abi.encodeCall(
            SafeSmartAccount.execTransaction, (to, 0, data, operation, 0, 0, 0, address(0), payable(0), signature)
        );
    }

    function sign(
        Client storage self,
        address to,
        bytes memory data,
        Enum.Operation operation,
        address sender,
        string memory derivationPath
    ) internal returns (bytes memory) {
        uint256 nonce = getNonce(self);
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
            bytes memory output = vm.ffi(inputs);
            return output;
        } else {
            Signature memory sig;
            (sig.v, sig.r, sig.s) = vm.sign(sender, getSafeTxHash(self, to, 0, data, Enum.Operation.Call, nonce));
            return abi.encodePacked(sig.r, sig.s, sig.v);
        }
    }
}
