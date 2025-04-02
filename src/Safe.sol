// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {HTTP} from "../lib/solidity-http/src/HTTP.sol";
import {Safe as SafeSmartAccount} from "../lib/safe-smart-account/contracts/Safe.sol";
import {Enum} from "../lib/safe-smart-account/contracts/common/Enum.sol";

library Safe {
    using HTTP for *;

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    error ApiKitUrlNotFound(uint256 chainId);

    struct Instance {
        address safe;
        HTTP.Client http;
        mapping(uint256 => string) urls;
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

    function proposeTransaction(
        Client storage self,
        address to,
        bytes memory data,
        address sender,
        bytes memory signature
    ) internal {
        return proposeTransaction(self, to, 0, data, Enum.Operation.Call, sender, signature, getNonce(self));
    }

    function proposeTransaction(Client storage self, address to, bytes memory data, address sender) internal {
        Signature memory sig;
        uint256 nonce = getNonce(self);
        (sig.v, sig.r, sig.s) = vm.sign(sender, getSafeTxHash(self, to, 0, data, Enum.Operation.Call, nonce));
        bytes memory signature = abi.encodePacked(sig.r, sig.s, sig.v);
        return proposeTransaction(self, to, 0, data, Enum.Operation.Call, sender, signature, nonce);
    }

    function getExecTransactionData(Client storage, address to, bytes memory data)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            SafeSmartAccount.execTransaction,
            (to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(0), new bytes(0))
        );
    }
}
