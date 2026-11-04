// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {Safe as SafeAccount} from "safe-smart-account/Safe.sol";
import {SafeProxy} from "safe-smart-account/proxies/SafeProxy.sol";
import {MultiSendCallOnly} from "safe-smart-account/libraries/MultiSendCallOnly.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

contract MultiSendOverrideReceiver {
    uint256 public calls;
    address public sender;

    function ping() external {
        calls++;
        sender = msg.sender;
    }
}

contract SafeMultiSendOverrideTest is Test {
    using Safe for *;

    Safe.Client safe;
    SafeAccount account;
    MultiSendCallOnly multiSend;
    MultiSendOverrideReceiver receiver;

    function setUp() public {
        SafeAccount singleton = new SafeAccount();
        account = SafeAccount(payable(address(new SafeProxy(address(singleton)))));
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        account.setup(owners, 1, address(0), "", address(0), address(0), 0, payable(address(0)));
        safe.initialize(address(account));
        multiSend = new MultiSendCallOnly();
        receiver = new MultiSendOverrideReceiver();
    }

    function test_Safe_multiSendOverride_withoutCode_rejectsBatch() public {
        address emptyTarget = makeAddr("empty multisend");
        safe.withMultiSendCallOnly(emptyTarget);

        vm.expectRevert(abi.encodeWithSelector(Safe.MultiSendCallOnlyHasNoCode.selector, emptyTarget));
        this.exposedBatch();
        assertEq(account.nonce(), 0);
        assertEq(receiver.calls(), 0);
    }

    function test_Safe_multiSendOverride_checksCodeWhenUsed() public {
        safe.withMultiSendCallOnly(address(multiSend));
        vm.etch(address(multiSend), "");

        vm.expectRevert(abi.encodeWithSelector(Safe.MultiSendCallOnlyHasNoCode.selector, address(multiSend)));
        this.exposedBatch();
    }

    function test_Safe_multiSendOverride_otherChain_doesNotInspectLocalCode() public {
        address remoteTarget = makeAddr("remote multisend");
        safe.withMultiSendCallOnly(remoteTarget);
        assertEq(address(safe.getMultiSendCallOnly(block.chainid + 1)), remoteTarget);
    }

    function test_Safe_multiSendOverride_withCode_executesBatch() public {
        safe.withMultiSendCallOnly(address(multiSend));
        (address[] memory targets, bytes[] memory datas) = _batch();
        (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
        assertEq(to, address(multiSend));
        bytes32 hash = safe.getSafeTxHash(to, 0, data, Enum.Operation.DelegateCall, 0);
        bytes[] memory signatures = safe.getApprovedHashSignatures(hash, address(this));
        bytes memory execData = safe.getExecTransactionsDataWithSignatures(targets, datas, signatures, 0);

        (bool ok, bytes memory result) = address(account).call(execData);
        assertTrue(ok);
        assertTrue(abi.decode(result, (bool)));
        assertEq(account.nonce(), 1);
        assertEq(receiver.calls(), 2);
        assertEq(receiver.sender(), address(account));
    }

    function exposedBatch() external view returns (address, bytes memory) {
        (address[] memory targets, bytes[] memory datas) = _batch();
        return safe.getProposeTransactionsTargetAndData(targets, datas);
    }

    function _batch() private view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](2);
        datas = new bytes[](2);
        targets[0] = address(receiver);
        targets[1] = address(receiver);
        datas[0] = abi.encodeCall(receiver.ping, ());
        datas[1] = abi.encodeCall(receiver.ping, ());
    }
}
