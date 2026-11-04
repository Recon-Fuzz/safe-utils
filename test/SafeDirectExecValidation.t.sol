// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {Safe as SafeAccount} from "safe-smart-account/Safe.sol";
import {SafeProxy} from "safe-smart-account/proxies/SafeProxy.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

contract SignatureValidationReceiver {
    uint256 public calls;
    address public sender;

    function ping() external {
        calls++;
        sender = msg.sender;
    }
}

/// @notice Signature and approval checks against a locally deployed canonical Safe.
contract SafeDirectExecValidationTest is Test {
    using Safe for *;

    uint256 constant CURVE_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    Safe.Client safe;
    SafeAccount account;
    SignatureValidationReceiver receiver;
    address[] owners;
    uint256[] ownerKeys;
    address nonOwnerExecutor = makeAddr("executor");

    function setUp() public {
        SafeAccount singleton = new SafeAccount();
        account = SafeAccount(payable(address(new SafeProxy(address(singleton)))));
        for (uint256 i; i < 3; i++) {
            ownerKeys.push(i + 1);
            owners.push(vm.addr(i + 1));
        }
        account.setup(owners, 2, address(0), "", address(0), address(0), 0, payable(address(0)));
        safe.initialize(address(account));
        receiver = new SignatureValidationReceiver();
    }

    function test_Safe_execWithSignatures_forgedApprovalEntries_rejectedBySafe() public {
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _approvalSignature(owners[0]);
        signatures[1] = _approvalSignature(owners[1]);

        // The helper recognizes the owners, but the Safe must verify their actual approvals.
        bytes memory execData = _execData(signatures, 0);
        _assertMissingApproval(nonOwnerExecutor, execData);
        assertEq(account.nonce(), 0);
        assertEq(receiver.calls(), 0);
    }

    function test_Safe_execWithSignatures_implicitApproval_requiresMatchingExecutor() public {
        _approve(owners[0], _hash(0));
        bytes[] memory signatures = safe.getApprovedHashSignatures(_hash(0), owners[1]);
        assertEq(signatures.length, 2);
        bytes memory execData = _execData(signatures, 0);

        _assertMissingApproval(nonOwnerExecutor, execData);
        assertEq(account.nonce(), 0);
        assertEq(receiver.calls(), 0);

        _exec(owners[1], execData);
        assertEq(account.nonce(), 1);
        assertEq(receiver.calls(), 1);
        assertEq(receiver.sender(), address(account));
    }

    function test_Safe_execWithSignatures_approvals_boundToTransactionHash() public {
        _approve(owners[0], _hash(0));
        _approve(owners[1], _hash(0));
        bytes[] memory signatures = safe.getApprovedHashSignatures(_hash(0), nonOwnerExecutor);
        assertEq(signatures.length, 2);

        SignatureValidationReceiver otherReceiver = new SignatureValidationReceiver();
        bytes memory execData = safe.getExecTransactionDataWithSignatures(
            address(otherReceiver), abi.encodeCall(otherReceiver.ping, ()), signatures, 0
        );
        _assertMissingApproval(nonOwnerExecutor, execData);
        assertEq(account.nonce(), 0);
        assertEq(otherReceiver.calls(), 0);

        _exec(nonOwnerExecutor, _execData(signatures, 0));
        assertEq(account.nonce(), 1);
        assertEq(receiver.calls(), 1);
    }

    function test_Safe_execWithSignatures_approvals_boundToCurrentNonce() public {
        _approve(owners[0], _hash(1));
        _approve(owners[1], _hash(1));
        bytes[] memory signatures = safe.getApprovedHashSignatures(_hash(1), nonOwnerExecutor);
        assertEq(signatures.length, 2);
        assertEq(safe.getApprovedHashSignatures(_hash(0), nonOwnerExecutor).length, 0);
        bytes memory execData = _execData(signatures, 1);

        // execTransaction uses the Safe's current nonce, regardless of the helper's explicit nonce.
        _assertMissingApproval(nonOwnerExecutor, execData);
        assertEq(account.nonce(), 0);
        assertEq(receiver.calls(), 0);

        bytes[] memory currentSignatures = new bytes[](2);
        currentSignatures[0] = _sign(0, 0, false);
        currentSignatures[1] = _sign(1, 0, false);
        _exec(nonOwnerExecutor, _execData(currentSignatures, 0));
        _exec(nonOwnerExecutor, execData);
        assertEq(account.nonce(), 2);
        assertEq(receiver.calls(), 2);
    }

    function test_Safe_combineSignatures_revertsWithMalformedLength() public {
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = new bytes(64);
        signatures[1] = _sign(1, 0, false);

        vm.expectRevert(abi.encodeWithSelector(Safe.InvalidSignatureLength.selector, 0, 64));
        this.exposedCombineSignatures(signatures);
    }

    function test_Safe_combineSignatures_revertsWithContractSignature() public {
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = abi.encodePacked(bytes32(uint256(uint160(owners[0]))), bytes32(0), uint8(0));
        signatures[1] = _sign(1, 0, false);

        vm.expectRevert(abi.encodeWithSelector(Safe.UnsupportedSignatureType.selector, 0, 0));
        this.exposedCombineSignatures(signatures);
    }

    function test_Safe_combineSignatures_malleatedSignature_cannotCountOwnerTwice() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKeys[0], _hash(0));
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = abi.encodePacked(r, s, v);
        signatures[1] = abi.encodePacked(r, bytes32(CURVE_ORDER - uint256(s)), v == 27 ? uint8(28) : uint8(27));

        vm.expectRevert(abi.encodeWithSelector(Safe.DuplicateSigner.selector, owners[0]));
        this.exposedCombineSignatures(signatures);
    }

    function test_Safe_execWithSignatures_allOwnersApproved_nonOwnerExecutes() public {
        for (uint256 i; i < owners.length; i++) {
            _approve(owners[i], _hash(0));
        }
        bytes[] memory signatures = safe.getApprovedHashSignatures(_hash(0), nonOwnerExecutor);
        assertEq(signatures.length, 3);

        _exec(nonOwnerExecutor, _execData(signatures, 0));
        assertEq(account.nonce(), 1);
        assertEq(receiver.calls(), 1);
        assertEq(receiver.sender(), address(account));
    }

    function testFuzz_Safe_execWithSignatures_mixedFormatsAndOwnerOrder_executes(uint8 permutation, uint8 modes)
        public
    {
        permutation = uint8(bound(permutation, 0, 5));
        uint256[2] memory order;
        order[0] = permutation / 2;
        order[1] = (order[0] + (permutation % 2 == 0 ? 1 : 2)) % 3;
        bytes[] memory signatures = new bytes[](2);
        for (uint256 i; i < signatures.length; i++) {
            uint256 ownerIndex = order[i];
            uint8 mode = (modes >> (i * 2)) & 3;
            if (mode == 0) {
                _approve(owners[ownerIndex], _hash(0));
                signatures[i] = _approvalSignature(owners[ownerIndex]);
            } else {
                signatures[i] = _sign(ownerIndex, 0, mode == 1);
            }
        }

        _exec(nonOwnerExecutor, _execData(signatures, 0));
        assertEq(account.nonce(), 1);
        assertEq(receiver.calls(), 1);
        assertEq(receiver.sender(), address(account));
    }

    function exposedCombineSignatures(bytes[] memory signatures) external view returns (bytes memory) {
        return safe.combineSignatures(_hash(0), signatures);
    }

    function _hash(uint256 nonce) private view returns (bytes32) {
        return safe.getSafeTxHash(address(receiver), 0, abi.encodeCall(receiver.ping, ()), Enum.Operation.Call, nonce);
    }

    function _sign(uint256 ownerIndex, uint256 nonce, bool ethSign) private view returns (bytes memory) {
        bytes32 digest = _hash(nonce);
        if (ethSign) digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKeys[ownerIndex], digest);
        return abi.encodePacked(r, s, ethSign ? v + 4 : v);
    }

    function _approvalSignature(address owner) private pure returns (bytes memory) {
        return abi.encodePacked(bytes32(uint256(uint160(owner))), bytes32(0), uint8(1));
    }

    function _execData(bytes[] memory signatures, uint256 nonce) private view returns (bytes memory) {
        return safe.getExecTransactionDataWithSignatures(
            address(receiver), abi.encodeCall(receiver.ping, ()), signatures, nonce
        );
    }

    function _approve(address owner, bytes32 digest) private {
        vm.prank(owner);
        account.approveHash(digest);
    }

    function _assertMissingApproval(address executor, bytes memory execData) private {
        vm.prank(executor);
        (bool ok, bytes memory ret) = address(account).call(execData);
        assertFalse(ok, "Safe accepted an unapproved transaction");
        assertEq(ret, abi.encodeWithSignature("Error(string)", "GS025"));
    }

    function _exec(address executor, bytes memory execData) private {
        vm.prank(executor);
        (bool ok, bytes memory ret) = address(account).call(execData);
        assertTrue(ok, "call to Safe reverted");
        assertTrue(abi.decode(ret, (bool)), "execTransaction returned false");
    }
}
