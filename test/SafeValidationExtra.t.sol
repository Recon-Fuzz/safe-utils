// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Safe} from "../src/Safe.sol";
import {Safe as SafeSmartAccount} from "safe-smart-account/Safe.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";
import {BaseProposalFixture} from "./SafeValidation.t.sol";

/// @notice Differential hash coverage against a local Safe, without an RPC connection.
contract SafeHashesLocalTest is BaseProposalFixture {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 nonce;
    }

    function testFuzz_Safe_getSafeTxHashes_matchesLocalSafe(
        uint64 chainId,
        Transaction memory transaction,
        bool delegateCall
    ) public {
        vm.chainId(chainId);
        SafeSmartAccount account = new SafeSmartAccount();
        Enum.Operation operation = delegateCall ? Enum.Operation.DelegateCall : Enum.Operation.Call;
        Safe.SafeTxHashes memory hashes = Safe.getSafeTxHashes(
            address(account), chainId, transaction.to, transaction.value, transaction.data, operation, transaction.nonce
        );

        assertEq(hashes.domainSeparator, account.domainSeparator());
        assertEq(hashes.safeTxHash, _accountHash(account, transaction, operation));
        assertEq(
            abi.encodePacked(hex"1901", hashes.domainSeparator, hashes.messageHash),
            _accountTransactionData(account, transaction, operation)
        );
    }

    function _accountHash(SafeSmartAccount account, Transaction memory transaction, Enum.Operation operation)
        private
        view
        returns (bytes32)
    {
        return account.getTransactionHash(
            transaction.to,
            transaction.value,
            transaction.data,
            operation,
            0,
            0,
            0,
            address(0),
            address(0),
            transaction.nonce
        );
    }

    function _accountTransactionData(SafeSmartAccount account, Transaction memory transaction, Enum.Operation operation)
        private
        view
        returns (bytes memory)
    {
        return account.encodeTransactionData(
            transaction.to,
            transaction.value,
            transaction.data,
            operation,
            0,
            0,
            0,
            address(0),
            address(0),
            transaction.nonce
        );
    }
}

/// @notice Reject responses with unsupported signed fields or malformed required values.
contract SafeValidationNegativeTest is BaseProposalFixture {
    using Safe for Safe.Client;

    Safe.Client safe;
    string json;
    address to;
    bytes data;

    function setUp() public {
        vm.chainId(BASE_CHAIN_ID);
        safe.initialize(SAFE_ADDRESS);
        json = vm.readFile("test/fixtures/base-multisig-transaction.json");
        to = vm.parseJsonAddress(json, ".to");
        data = vm.parseJsonBytes(json, ".data");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongValue() public {
        _expectMismatch('"value": "0"', '"value": "1"', "value", "0", "1");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnNonzeroSafeTxGas() public {
        _expectMismatch('"safeTxGas": "0"', '"safeTxGas": "1"', "safeTxGas", "0", "1");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnNonzeroBaseGas() public {
        _expectMismatch('"baseGas": "0"', '"baseGas": "1"', "baseGas", "0", "1");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnNonzeroGasPrice() public {
        _expectMismatch('"gasPrice": "0"', '"gasPrice": "1"', "gasPrice", "0", "1");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnNonzeroGasToken() public {
        _expectMismatch(
            '"gasToken": null',
            '"gasToken": "0x0000000000000000000000000000000000000001"',
            "gasToken",
            vm.toString(address(0)),
            vm.toString(address(1))
        );
    }

    function test_Safe_validateProposedTransactionJson_revertsOnNonzeroRefundReceiver() public {
        _expectMismatch(
            '"refundReceiver": null',
            '"refundReceiver": "0x0000000000000000000000000000000000000001"',
            "refundReceiver",
            vm.toString(address(0)),
            vm.toString(address(1))
        );
    }

    function test_Safe_validateProposedTransactionJson_recomputesMatchingResponseHash() public {
        // The response and requested hash agree, but neither matches the signed transaction fields.
        bytes32 dishonestHash = bytes32(uint256(1));
        string memory response = _replace(vm.toString(PROPOSAL_SAFE_TX_HASH), vm.toString(dishonestHash));
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector,
                "recomputed safeTxHash",
                vm.toString(PROPOSAL_SAFE_TX_HASH),
                vm.toString(dishonestHash)
            )
        );
        this.exposedValidate(response, dishonestHash);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnMalformedJson() public {
        vm.expectRevert();
        this.exposedValidate("{", PROPOSAL_SAFE_TX_HASH);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnInvalidOperation() public {
        _expectRejected('"operation": 1', '"operation": 256');
        _expectRejected('"operation": 1', '"operation": -1');
    }

    function test_Safe_validateProposedTransactionJson_revertsOnInvalidNumbers() public {
        _expectRejected('"nonce": "3"', '"nonce": []');
        _expectRejected('"nonce": "3"', '"nonce": null');
        _expectRejected('"gasPrice": "0"', '"gasPrice": "-1"');
    }

    function test_Safe_validateProposedTransactionJson_revertsOnMissingRequiredFields() public {
        _expectRejected('"safeTxGas": "0",', "");
        _expectRejected(string.concat('"data": "', vm.toString(data), '",'), "");
    }

    function test_Safe_validateProposedTransactionJson_revertsOnInvalidAddresses() public {
        _expectRejected('"gasToken": null', '"gasToken": {}');
        _expectRejected('"refundReceiver": null', '"refundReceiver": "invalid"');
    }

    function test_Safe_validateProposedTransactionJson_revertsOnInvalidData() public {
        string memory original = string.concat('"data": "', vm.toString(data), '"');
        _expectRejected(original, '"data": null');
        _expectRejected(original, '"data": "nothex"');
    }

    function test_Safe_validateProposedTransactionJson_acceptsMissingNullableAddresses() public view {
        string memory response = _replace('"gasToken": null,', "");
        response = vm.replace(response, '"refundReceiver": null,', "");
        Safe.SafeTxHashes memory hashes = this.exposedValidate(response, PROPOSAL_SAFE_TX_HASH);
        assertEq(hashes.safeTxHash, PROPOSAL_SAFE_TX_HASH);
    }

    function exposedValidate(string memory response, bytes32 safeTxHash)
        external
        view
        returns (Safe.SafeTxHashes memory)
    {
        return safe.validateProposedTransactionJson(
            response, safeTxHash, to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE
        );
    }

    function _expectMismatch(
        string memory original,
        string memory replacement,
        string memory field,
        string memory expected,
        string memory actual
    ) private {
        string memory response = _replace(original, replacement);
        vm.expectRevert(abi.encodeWithSelector(Safe.ProposedTransactionMismatch.selector, field, expected, actual));
        this.exposedValidate(response, PROPOSAL_SAFE_TX_HASH);
    }

    function _expectRejected(string memory original, string memory replacement) private {
        string memory response = _replace(original, replacement);
        // Malformed JSON values can fail in the parser before the comparison reports a mismatch.
        vm.expectRevert();
        this.exposedValidate(response, PROPOSAL_SAFE_TX_HASH);
    }

    function _replace(string memory original, string memory replacement) private view returns (string memory) {
        string memory response = vm.replace(json, original, replacement);
        assertTrue(keccak256(bytes(response)) != keccak256(bytes(json)), "fixture replacement did not match");
        return response;
    }
}
