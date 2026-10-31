// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";
import {ISafeSmartAccount} from "../src/ISafeSmartAccount.sol";
import {Enum} from "safe-smart-account/common/Enum.sol";

interface ISafeProxyFactory {
    function createProxyWithNonce(address singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);
}

interface ISafeSetup {
    function setup(
        address[] calldata owners,
        uint256 threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

interface IERC20Transfer {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

/// @notice Tests for executing a threshold-2 Safe directly, without the Safe Transaction Service.
///
///         Each test deploys a fresh 2-of-3 Safe through the canonical v1.4.1 SafeProxyFactory on a Base fork,
///         so owners and keys are known and no storage writes are needed.
contract SafeDirectExecTest is Test {
    using Safe for *;

    // https://github.com/safe-global/safe-deployments/blob/main/src/assets/v1.4.1/safe_proxy_factory.json
    address constant SAFE_PROXY_FACTORY = 0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67;
    // https://github.com/safe-global/safe-deployments/blob/main/src/assets/v1.4.1/safe_l2.json
    address constant SAFE_L2_SINGLETON = 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    Safe.Client safe;
    address safeAddress;

    address owner1;
    uint256 owner1Key;
    address owner2;
    uint256 owner2Key;
    address owner3;
    uint256 owner3Key;

    address recipient = makeAddr("recipient");
    address nonOwnerExecutor = makeAddr("executor");

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");

        (owner1, owner1Key) = makeAddrAndKey("owner1");
        (owner2, owner2Key) = makeAddrAndKey("owner2");
        (owner3, owner3Key) = makeAddrAndKey("owner3");
        vm.rememberKey(owner1Key);
        vm.rememberKey(owner2Key);
        vm.rememberKey(owner3Key);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;
        bytes memory initializer = abi.encodeCall(
            ISafeSetup.setup, (owners, 2, address(0), "", address(0), address(0), 0, payable(address(0)))
        );
        safeAddress = ISafeProxyFactory(SAFE_PROXY_FACTORY).createProxyWithNonce(SAFE_L2_SINGLETON, initializer, 0);
        safe.initialize(safeAddress);

        assertEq(ISafeSmartAccount(safeAddress).getThreshold(), 2);
        deal(WETH, safeAddress, 1 ether);
    }

    // -------------------------------------------------------------------------
    // Offline signatures
    // -------------------------------------------------------------------------

    function test_Safe_execWithSignatures_offlineSignaturesUnsorted_executes() public {
        bytes memory data = _transferData(0.1 ether);
        (address low, address high) = _sortedPair(owner1, owner2);

        // Pass the higher address first: combineSignatures must sort them.
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = safe.sign(WETH, data, Enum.Operation.Call, high, "");
        signatures[1] = safe.sign(WETH, data, Enum.Operation.Call, low, "");

        bytes memory execData = safe.getExecTransactionDataWithSignatures(WETH, data, signatures);
        _exec(nonOwnerExecutor, execData);

        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.1 ether);
        assertEq(safe.getNonce(), 1);
    }

    function test_Safe_execWithSignatures_ethSignSignature_executes() public {
        // eth_sign signature with v + 4, the format {sign} produces for Trezor
        bytes memory data = _transferData(0.1 ether);
        bytes32 safeTxHash = safe.getSafeTxHash(WETH, 0, data, Enum.Operation.Call, safe.getNonce());
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(owner3Key, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", safeTxHash)));

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = abi.encodePacked(r, s, v + 4);
        signatures[1] = safe.sign(WETH, data, Enum.Operation.Call, owner1, "");

        _exec(nonOwnerExecutor, safe.getExecTransactionDataWithSignatures(WETH, data, signatures));
        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.1 ether);
    }

    // -------------------------------------------------------------------------
    // On-chain approvals
    // -------------------------------------------------------------------------

    function test_Safe_execWithSignatures_approveHashAndExecutor_executes() public {
        bytes memory data = _transferData(0.1 ether);
        bytes32 safeTxHash = safe.getSafeTxHash(WETH, 0, data, Enum.Operation.Call, safe.getNonce());

        // owner1 approves on-chain with an ordinary transaction
        _exec(owner1, safe.getApproveHashData(safeTxHash));
        assertEq(ISafeSmartAccount(safeAddress).approvedHashes(owner1, safeTxHash), 1);

        // owner2 executes: its approval is implicit, so no signature is needed from it
        bytes[] memory signatures = safe.getApprovedHashSignatures(safeTxHash, owner2);
        assertEq(signatures.length, 2);

        _exec(owner2, safe.getExecTransactionDataWithSignatures(WETH, data, signatures));
        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.1 ether);
    }

    function test_Safe_execWithSignatures_mixApproveHashAndOfflineSignature_executes() public {
        bytes memory data = _transferData(0.1 ether);
        bytes32 safeTxHash = safe.getSafeTxHash(WETH, 0, data, Enum.Operation.Call, safe.getNonce());

        _exec(owner3, safe.getApproveHashData(safeTxHash));
        // A non-owner executes, so it adds no implicit approval
        bytes[] memory approved = safe.getApprovedHashSignatures(safeTxHash, nonOwnerExecutor);
        assertEq(approved.length, 1);

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = approved[0];
        signatures[1] = safe.sign(WETH, data, Enum.Operation.Call, owner1, "");

        _exec(nonOwnerExecutor, safe.getExecTransactionDataWithSignatures(WETH, data, signatures));
        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.1 ether);
    }

    // -------------------------------------------------------------------------
    // Rejections
    // -------------------------------------------------------------------------

    function test_Safe_execWithSignatures_revertsWithTooFewSignatures() public {
        bytes memory data = _transferData(0.1 ether);
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = safe.sign(WETH, data, Enum.Operation.Call, owner1, "");

        vm.expectRevert(abi.encodeWithSelector(Safe.NotEnoughSignatures.selector, 1, 2));
        this.exposedGetExecTransactionDataWithSignatures(WETH, data, signatures);
    }

    function test_Safe_execWithSignatures_revertsWithNonOwnerSignature() public {
        bytes memory data = _transferData(0.1 ether);
        (address stranger, uint256 strangerKey) = makeAddrAndKey("stranger");
        vm.rememberKey(strangerKey);

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = safe.sign(WETH, data, Enum.Operation.Call, owner1, "");
        signatures[1] = safe.sign(WETH, data, Enum.Operation.Call, stranger, "");

        vm.expectRevert(abi.encodeWithSelector(Safe.SignerNotOwner.selector, stranger));
        this.exposedGetExecTransactionDataWithSignatures(WETH, data, signatures);
    }

    function test_Safe_execWithSignatures_revertsWithDuplicateOwner() public {
        bytes memory data = _transferData(0.1 ether);
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = safe.sign(WETH, data, Enum.Operation.Call, owner1, "");
        signatures[1] = signatures[0];

        vm.expectRevert(abi.encodeWithSelector(Safe.DuplicateSigner.selector, owner1));
        this.exposedGetExecTransactionDataWithSignatures(WETH, data, signatures);
    }

    function test_Safe_execWithSignatures_revertsWithSignatureForAnotherNonce() public {
        // Signed for nonce 1 but checked against the current nonce 0: recovers to an unrelated address
        bytes memory data = _transferData(0.1 ether);
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = safe.sign(WETH, data, Enum.Operation.Call, owner1, 1, "");
        signatures[1] = safe.sign(WETH, data, Enum.Operation.Call, owner2, 1, "");

        vm.expectPartialRevert(Safe.SignerNotOwner.selector);
        this.exposedGetExecTransactionDataWithSignatures(WETH, data, signatures);
    }

    // -------------------------------------------------------------------------
    // Batch and nonce
    // -------------------------------------------------------------------------

    function test_Safe_execTransactionsWithSignatures_multiSendBatch_executes() public {
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = WETH;
        datas[0] = _transferData(0.1 ether);
        targets[1] = WETH;
        datas[1] = _transferData(0.2 ether);

        // Batches are signed with DelegateCall, as for proposeTransactionsWithSignature
        (address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = safe.sign(to, data, Enum.Operation.DelegateCall, owner3, "");
        signatures[1] = safe.sign(to, data, Enum.Operation.DelegateCall, owner2, "");

        _exec(nonOwnerExecutor, safe.getExecTransactionsDataWithSignatures(targets, datas, signatures));
        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.3 ether);
        assertEq(safe.getNonce(), 1);
    }

    function test_Safe_execWithSignatures_explicitNonce_sequentialTransactions() public {
        // Prepare two transactions before either executes; the second needs nonce 1.
        bytes memory dataA = _transferData(0.1 ether);
        bytes memory dataB = _transferData(0.2 ether);

        bytes[] memory sigsA = new bytes[](2);
        sigsA[0] = safe.sign(WETH, dataA, Enum.Operation.Call, owner1, 0, "");
        sigsA[1] = safe.sign(WETH, dataA, Enum.Operation.Call, owner2, 0, "");
        bytes[] memory sigsB = new bytes[](2);
        sigsB[0] = safe.sign(WETH, dataB, Enum.Operation.Call, owner1, 1, "");
        sigsB[1] = safe.sign(WETH, dataB, Enum.Operation.Call, owner3, 1, "");

        bytes memory execA = safe.getExecTransactionDataWithSignatures(WETH, dataA, sigsA, 0);
        bytes memory execB = safe.getExecTransactionDataWithSignatures(WETH, dataB, sigsB, 1);

        _exec(nonOwnerExecutor, execA);
        _exec(nonOwnerExecutor, execB);
        assertEq(IERC20Transfer(WETH).balanceOf(recipient), 0.3 ether);
        assertEq(safe.getNonce(), 2);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function exposedGetExecTransactionDataWithSignatures(address to, bytes memory data, bytes[] memory signatures)
        external
        view
        returns (bytes memory)
    {
        return safe.getExecTransactionDataWithSignatures(to, data, signatures);
    }

    function _transferData(uint256 amount) private view returns (bytes memory) {
        return abi.encodeCall(IERC20Transfer.transfer, (recipient, amount));
    }

    function _sortedPair(address a, address b) private pure returns (address, address) {
        return uint160(a) < uint160(b) ? (a, b) : (b, a);
    }

    function _exec(address sender, bytes memory callData) private {
        vm.prank(sender);
        (bool ok, bytes memory ret) = safeAddress.call(callData);
        assertTrue(ok, "call to Safe reverted");
        if (ret.length == 32) assertTrue(abi.decode(ret, (bool)), "execTransaction returned false");
    }
}
