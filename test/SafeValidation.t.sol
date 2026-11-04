// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {ISafeSmartAccount} from "../src/ISafeSmartAccount.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

interface ISafeDomain {
    function domainSeparator() external view returns (bytes32);
}

/// @notice Shared values of the Base proposal in test/fixtures/base-multisig-transaction.json.
///         The fixture is the Transaction Service response for
///         GET /v2/multisig-transactions/0x73ad…cdec/ on Base, fetched on 2026-10-31: a MultiSend batch of two
///         WETH.withdraw(0) calls, nonce 3, proposed for the test Safe used across this suite.
abstract contract BaseProposalFixture is Test {
    address constant SAFE_ADDRESS = 0xF3a292Dda3F524EA20b5faF2EE0A1c4abA665e4F;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant PROPOSAL_NONCE = 3;

    bytes32 constant PROPOSAL_SAFE_TX_HASH = 0x73ad1f3077d266e79c4934abad9c29c90ccfce33c2674a4d0787bb6d4e54cdec;
    // Computed with viem 2.57.5 hashDomain / hashStruct; the safeTxHash also matches the Transaction Service.
    bytes32 constant PROPOSAL_DOMAIN_SEPARATOR = 0x0fe2094a92e7bdf87c5ea791a6b9179173226e32eb36893655ad6a4792eb8fcc;
    bytes32 constant PROPOSAL_MESSAGE_HASH = 0x3350bc3861b7d6833ee7d8d7dff0682d0a66e84d28e0f6f46f4ffbd3cae5fcf0;

    function _batch(uint256 secondAmount) internal pure returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](2);
        datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = abi.encodeCall(IWETH.withdraw, (0));
        targets[1] = WETH;
        datas[1] = abi.encodeCall(IWETH.withdraw, (secondAmount));
    }
}

/// @notice Hash computation without a fork: known vectors.
contract SafeHashesTest is BaseProposalFixture {
    function test_Safe_getSafeTxHashes_matchesViemVector() public pure {
        // viem 2.57.5: hashDomain, hashStruct and hashTypedData with the SafeTx type of
        // safe-smart-account/src/utils/execution.ts and zeroed gas fields.
        Safe.SafeTxHashes memory hashes = Safe.getSafeTxHashes(
            0x1234567890123456789012345678901234567890,
            1,
            0x000000000000000000000000000000000000dEaD,
            1 ether,
            hex"deadbeef",
            Enum.Operation.DelegateCall,
            42
        );
        assertEq(hashes.domainSeparator, 0x3888d34b69042fc92d822804722836d705e22c56efd96e8e04c0de3ec131831b);
        assertEq(hashes.messageHash, 0xd41fefa5aaf04dff0dd6dca13ceb09330bc0a4eaac556a841639271dfb984254);
        assertEq(hashes.safeTxHash, 0x1fa90a462d4a2e896cbedc3b223562bf9cbd9981668bd9b6982fa67172703bec);
    }

    function test_Safe_getSafeTxHashes_matchesTransactionServiceHash() public {
        string memory json = vm.readFile("test/fixtures/base-multisig-transaction.json");
        Safe.SafeTxHashes memory hashes = Safe.getSafeTxHashes(
            SAFE_ADDRESS,
            BASE_CHAIN_ID,
            vm.parseJsonAddress(json, ".to"),
            0,
            vm.parseJsonBytes(json, ".data"),
            Enum.Operation.DelegateCall,
            PROPOSAL_NONCE
        );
        assertEq(hashes.domainSeparator, PROPOSAL_DOMAIN_SEPARATOR);
        assertEq(hashes.messageHash, PROPOSAL_MESSAGE_HASH);
        assertEq(hashes.safeTxHash, PROPOSAL_SAFE_TX_HASH);
    }
}

/// @notice Hash computation against a real Safe v1.4.1 on a Base fork.
contract SafeHashesForkTest is BaseProposalFixture {
    using Safe for *;

    Safe.Client safe;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");
        safe.initialize(SAFE_ADDRESS);
    }

    function test_Safe_getSafeTxHashes_matchesSafeContract() public view {
        bytes memory data = abi.encodeCall(IWETH.withdraw, (0));
        uint256 nonce = safe.getNonce();
        Safe.SafeTxHashes memory hashes = safe.getSafeTxHashes(WETH, 0, data, Enum.Operation.Call, nonce);

        assertEq(hashes.domainSeparator, ISafeDomain(SAFE_ADDRESS).domainSeparator());
        assertEq(hashes.safeTxHash, safe.getSafeTxHash(WETH, 0, data, Enum.Operation.Call, nonce));
    }

    function test_Safe_getSafeTxHashes_matchesSafeContractForBatch() public view {
        (address[] memory targets, bytes[] memory datas) = _batch(0);
        (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
        Safe.SafeTxHashes memory hashes = safe.getSafeTxHashes(to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);

        assertEq(hashes.safeTxHash, safe.getSafeTxHash(to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE));
        assertEq(hashes.safeTxHash, PROPOSAL_SAFE_TX_HASH);
    }

    function testFuzz_Safe_getSafeTxHashes_matchesSafeContract(
        address to,
        uint256 value,
        bytes memory data,
        bool delegateCall,
        uint256 nonce
    ) public view {
        Enum.Operation operation = delegateCall ? Enum.Operation.DelegateCall : Enum.Operation.Call;
        Safe.SafeTxHashes memory hashes = safe.getSafeTxHashes(to, value, data, operation, nonce);
        bytes32 expected = ISafeSmartAccount(SAFE_ADDRESS)
            .getTransactionHash(to, value, data, operation, 0, 0, 0, address(0), address(0), nonce);
        assertEq(hashes.safeTxHash, expected);
    }
}

/// @notice Validation against a fixture response: no fork and no Transaction Service needed.
contract SafeValidationTest is BaseProposalFixture {
    using Safe for *;

    Safe.Client safe;
    string json;

    function setUp() public {
        vm.chainId(BASE_CHAIN_ID);
        safe.initialize(SAFE_ADDRESS);
        json = vm.readFile("test/fixtures/base-multisig-transaction.json");
    }

    function test_Safe_validateProposedTransactionJson_matches() public view {
        (address to, bytes memory data) = _batchTargetAndData(0);
        Safe.SafeTxHashes memory hashes = safe.validateProposedTransactionJson(
            json, PROPOSAL_SAFE_TX_HASH, to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE
        );
        assertEq(hashes.domainSeparator, PROPOSAL_DOMAIN_SEPARATOR);
        assertEq(hashes.messageHash, PROPOSAL_MESSAGE_HASH);
        assertEq(hashes.safeTxHash, PROPOSAL_SAFE_TX_HASH);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongData() public {
        (address to, bytes memory data) = _batchTargetAndData(1);
        (, bytes memory proposedData) = _batchTargetAndData(0);
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector, "data", vm.toString(data), vm.toString(proposedData)
            )
        );
        this.exposedValidate(to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongNonce() public {
        (address to, bytes memory data) = _batchTargetAndData(0);
        vm.expectRevert(abi.encodeWithSelector(Safe.ProposedTransactionMismatch.selector, "nonce", "4", "3"));
        this.exposedValidate(to, 0, data, Enum.Operation.DelegateCall, 4);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongTo() public {
        (address to, bytes memory data) = _batchTargetAndData(0);
        address wrongTo = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector, "to", vm.toString(wrongTo), vm.toString(to)
            )
        );
        this.exposedValidate(wrongTo, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongOperation() public {
        (address to, bytes memory data) = _batchTargetAndData(0);
        vm.expectRevert(abi.encodeWithSelector(Safe.ProposedTransactionMismatch.selector, "operation", "0", "1"));
        this.exposedValidate(to, 0, data, Enum.Operation.Call, PROPOSAL_NONCE);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnWrongSafe() public {
        // The client uses its latest instance, so this points it at another Safe.
        safe.initialize(address(0xBEEF));
        (address to, bytes memory data) = _batchTargetAndData(0);
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector,
                "safe",
                vm.toString(address(0xBEEF)),
                vm.toString(SAFE_ADDRESS)
            )
        );
        this.exposedValidate(to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnOtherChain() public {
        vm.chainId(1);
        (address to, bytes memory data) = (vm.parseJsonAddress(json, ".to"), vm.parseJsonBytes(json, ".data"));
        Safe.SafeTxHashes memory onMainnet =
            Safe.getSafeTxHashes(SAFE_ADDRESS, 1, to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector,
                "recomputed safeTxHash",
                vm.toString(onMainnet.safeTxHash),
                vm.toString(PROPOSAL_SAFE_TX_HASH)
            )
        );
        this.exposedValidate(to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE);
    }

    function test_Safe_validateProposedTransactionJson_revertsOnOtherHash() public {
        bytes32 otherHash = bytes32(uint256(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Safe.ProposedTransactionMismatch.selector,
                "safeTxHash",
                vm.toString(otherHash),
                vm.toString(PROPOSAL_SAFE_TX_HASH)
            )
        );
        this.exposedValidateHash(otherHash);
    }

    /// @dev The Transaction Service returns null, not "0x", for an empty data payload.
    function test_Safe_validateProposedTransactionJson_acceptsNullData() public {
        Safe.SafeTxHashes memory expected = safe.getSafeTxHashes(WETH, 1 ether, "", Enum.Operation.Call, PROPOSAL_NONCE);
        string memory response = vm.replace(
            json,
            '"to": "0x40A2aCCbd92BCA938b02010E17A5b8929b49130D"',
            '"to": "0x4200000000000000000000000000000000000006"'
        );
        response = vm.replace(response, '"value": "0"', '"value": "1000000000000000000"');
        response = vm.replace(response, '"operation": 1', '"operation": 0');
        response = vm.replace(response, vm.toString(PROPOSAL_SAFE_TX_HASH), vm.toString(expected.safeTxHash));
        response =
            vm.replace(response, string.concat('"data": "', vm.parseJsonString(json, ".data"), '"'), '"data": null');

        Safe.SafeTxHashes memory hashes = safe.validateProposedTransactionJson(
            response, expected.safeTxHash, WETH, 1 ether, "", Enum.Operation.Call, PROPOSAL_NONCE
        );
        assertEq(hashes.safeTxHash, expected.safeTxHash);
    }

    function test_Safe_getProposedTransactionUrl() public view {
        assertEq(
            safe.getProposedTransactionUrl(BASE_CHAIN_ID, PROPOSAL_SAFE_TX_HASH),
            "https://api.safe.global/tx-service/base/api/v2/multisig-transactions/0x73ad1f3077d266e79c4934abad9c29c90ccfce33c2674a4d0787bb6d4e54cdec/"
        );
    }

    function exposedValidate(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 nonce)
        external
        view
        returns (Safe.SafeTxHashes memory)
    {
        return safe.validateProposedTransactionJson(json, PROPOSAL_SAFE_TX_HASH, to, value, data, operation, nonce);
    }

    function exposedValidateHash(bytes32 safeTxHash) external view returns (Safe.SafeTxHashes memory) {
        (address to, bytes memory data) = _batchTargetAndData(0);
        return safe.validateProposedTransactionJson(
            json, safeTxHash, to, 0, data, Enum.Operation.DelegateCall, PROPOSAL_NONCE
        );
    }

    function _batchTargetAndData(uint256 secondAmount) private view returns (address, bytes memory) {
        (address[] memory targets, bytes[] memory datas) = _batch(secondAmount);
        return safe.getProposeTransactionsTargetAndData(targets, datas);
    }
}
