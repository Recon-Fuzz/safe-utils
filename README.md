## safe-utils

Interact with the [Safe API](https://docs.safe.global/sdk/api-kit) from Foundry scripts.

### Installation

```bash
forge install Recon-Fuzz/safe-utils
```

### Usage

#### 1. Import the library

```solidity
import {Safe} from "safe-utils/Safe.sol";
```

#### 2. Initialize the client

Build the client by passing your safe address.

```solidity
using Safe for *;

Safe.Client safe;

function setUp() public {
  safe.initialize(safeAddress);
}
```

#### 3. Propose transactions

```solidity
safe.proposeTransaction(weth, abi.encodeCall(IWETH.withdraw, (0)), sender);
```

If you are using a hardware wallet, make sure to pass the derivation path as the last argument:

```solidity
safe.proposeTransaction(weth, abi.encodeCall(IWETH.withdraw, (0)), sender, "m/44'/60'/0'/0/0");
```

Ledger is the default. To sign with a Trezor instead, set the `HARDWARE_WALLET` environment variable:

```bash
HARDWARE_WALLET=trezor forge script ... --ffi
```

Proposing a transaction/transactions using a hardware wallet will also require pre-computing the signature, due to a (current) limitation with forge.

The first step is to pre-compute the signature:

```solidity
bytes memory signature = safe.sign(weth, abi.encodeCall(IWETH.withdraw, (0)), Enum.Operation.Call, sender, "m/44'/60'/0'/0/0");
```

Note that this call will fail if `forge script` is called with the `--ledger` or `--trezor` flag, as that would block this library's contracts from utilising the same device. Instead, pass the derivation path as an argument to the script.

The second step is to take the value for the returned `bytes` and provide them when proposing the transaction:

```solidity
safe.proposeTransactionWithSignature(weth, abi.encodeCall(IWETH.withdraw, (0)), sender, signature);
```

#### Batch transactions

```solidity
safe.proposeTransactions(targets, datas, sender, "m/44'/60'/0'/0/0");
```

For pre-computed signatures with hardware wallets:

```solidity
(address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
bytes memory signature = safe.sign(to, data, Enum.Operation.DelegateCall, sender, "m/44'/60'/0'/0/0");
safe.proposeTransactionsWithSignature(targets, datas, sender, signature);
```

**⚠️ Important**: Batch transactions require `Enum.Operation.DelegateCall` (not `Call`). Using `Call` causes signature validation errors.

Batches delegatecall `MultiSendCallOnly`. On a chain the Safe transaction service does not serve, the library uses the canonical v1.4.1 deployment, then v1.3.0, whichever has code on the current chain. For a deployment at another address, set it on the client:

```solidity
safe.withMultiSendCallOnly(0x...);
```

The override applies to every chain queried through that client. Clear it with `safe.withMultiSendCallOnly(address(0))` when it no longer applies. On the current chain, an override with no code reverts with `MultiSendCallOnlyHasNoCode` before a batch is built. Queries for another chain cannot check that chain's code.

Use only a trusted `MultiSendCallOnly` deployment. The batch delegatecalls this address in the Safe's context. Checking that code exists does not verify what the code does; the same limitation applies to automatic canonical-address fallback.

#### Direct execution with several owners (no Transaction Service)

On a chain without the Safe Transaction Service, owners can approve a transaction and anyone can execute it with `execTransaction`. Approvals come from offline signatures, on-chain `approveHash` calls, or a mix of both.

For a single call, collect signatures over its hash and pass them in any order:

```solidity
bytes32 singleHash = safe.getSafeTxHash(target, 0, data, Enum.Operation.Call, nonce);

// Both owners sign singleHash, for example with safe.sign(...).
bytes[] memory signatures = new bytes[](2);
signatures[0] = signatureFromOwnerA;
signatures[1] = signatureFromOwnerB;
bytes memory execData = safe.getExecTransactionDataWithSignatures(target, data, signatures, nonce);
```

For a batch, collect new signatures over the MultiSend payload with `DelegateCall`:

```solidity
(address batchTo, bytes memory batchData) = safe.getProposeTransactionsTargetAndData(targets, datas);
bytes32 batchHash = safe.getSafeTxHash(batchTo, 0, batchData, Enum.Operation.DelegateCall, nonce);

// Both owners sign batchHash. Signatures over singleHash cannot authorize this batch.
bytes[] memory batchSignatures = new bytes[](2);
batchSignatures[0] = batchSignatureFromOwnerA;
batchSignatures[1] = batchSignatureFromOwnerB;
bytes memory batchExecData = safe.getExecTransactionsDataWithSignatures(targets, datas, batchSignatures, nonce);
```

For on-chain approvals, an owner sends `approveHash` calldata to the Safe as an ordinary transaction. This works with `--ledger` or `--trezor` without the FFI signing step:

```solidity
bytes32 approvalHash = safe.getSafeTxHash(target, 0, data, Enum.Operation.Call, nonce);
bytes memory approveData = safe.getApproveHashData(approvalHash);

// After enough owners have approved on-chain, collect their entries and build execution calldata.
bytes[] memory approvals = safe.getApprovedHashSignatures(approvalHash, executor);
bytes memory approvedExecData = safe.getExecTransactionDataWithSignatures(target, data, approvals, nonce);
```

`getApprovedHashSignatures` also includes `executor` when it is an owner. That account must actually call `execTransaction` unless it has separately approved the hash on-chain. Pass `address(0)` when execution will come from a non-owner.

Offline signatures and approval entries can be combined in one `bytes[]`, with each owner appearing once. `combineSignatures(safeTxHash, signatures)` checks owner identities, duplicates and the threshold, then sorts the entries. For approval entries (`v = 1`), it does not verify consent: the Safe checks the recorded approval or the actual executor during execution. Building calldata successfully does not guarantee it can execute.

ECDSA signatures use `v = 27/28`. `eth_sign` signatures need `v + 4` (`31/32`), as `safe.sign` produces for Trezor. Contract signatures (`v = 0`) are not supported by these helpers. The execution helpers use zero ETH value and zero gas/refund fields.

#### Validate a proposal before signing

A hardware wallet shows only hashes. Before co-signing, check that a proposal on the Transaction Service matches the transaction your script builds:

```solidity
// Single transaction: compares the proposal with these locally supplied expectations
safe.validateProposedTransaction(safeTxHash, to, value, data, Enum.Operation.Call, nonce);

// Batch: rebuilds the MultiSend payload from targets and datas, as proposeTransactions does
safe.validateProposedTransactions(safeTxHash, targets, datas, nonce);
```

On success it logs the domain hash, message hash and safeTxHash to compare with the device screen. To compute them without the Transaction Service:

```solidity
Safe.SafeTxHashes memory hashes = safe.getSafeTxHashes(to, value, data, operation, nonce);
Safe.logSafeTxHashes(hashes);
```

`validateProposedTransactionJson` checks a response you already fetched, for example in tests.

Hash computation and proposal validation support Safe v1.3.0 and later. Older Safes use a different EIP-712 domain. These helpers require zero `safeTxGas`, `baseGas`, `gasPrice`, `gasToken` and `refundReceiver`, matching transactions proposed by this library. They compare calldata byte for byte without decoding it.

A differing field reverts with `ProposedTransactionMismatch(field, expected, actual)`. Malformed responses or missing required fields may instead produce a JSON parser error. Supply expected values from your own script; copying them from the response would defeat the comparison.

#### Simulation (no hardware wallet required)

Simulate transactions against a local fork before broadcasting. No signing device is needed — the library writes directly to the Safe's `approvedHashes` storage slot.

```solidity
// Single transaction
bool ok = safe.simulateTransactionNoSign(target, data, signerAddress);

// Batch
bool ok = safe.simulateTransactionsNoSign(targets, datas, signerAddress);

// Multi-sig (threshold > 1) — pass at least `threshold` valid owner addresses.
// Non-owners and duplicates in the array are silently filtered out.
address[] memory signers = new address[](2);
signers[0] = signer1;
signers[1] = signer2;
bool ok = safe.simulateTransactionMultiSigNoSign(target, data, signers);
bool ok = safe.simulateTransactionsMultiSigNoSign(targets, datas, signers);
```

All simulate functions return `true` on success and `false` on revert — they never throw, so you can inspect failures without aborting the script.

Mode detection helpers let you branch between simulation and broadcast in one script:

```solidity
if (Safe.isSimulationMode()) { /* fork run */ }
if (Safe.isBroadcastMode()) { /* --broadcast run */ }
```

Set the `SAFE_BROADCAST` environment variable to `true` to force broadcast mode regardless of the `--broadcast` flag (useful in CI).

#### SafeScriptBase

`SafeScriptBase` is an abstract Foundry script that wires up simulation and broadcast automatically. Extend it instead of writing the routing logic yourself:

```solidity
import {SafeScriptBase} from "safe-utils/SafeScriptBase.sol";

contract MyScript is SafeScriptBase {
    function run() external {
        _initializeSafe(); // reads DEPLOYER_SAFE_ADDRESS, SIGNER_ADDRESS, DERIVATION_PATH

        // Routes to simulate (no --broadcast) or propose (--broadcast) automatically
        _proposeTransaction(target, data, "Description shown in logs");

        // Batch
        _proposeTransactions(targets, datas, "Batch description");

        // Deployment — skips if code already present, reverts if missing after simulation
        _proposeTransactionWithVerification(factory, deployData, expectedAddr, "Deploy Foo");
    }
}
```

For multi-sig scripts use `_initializeSafeMultiSig()` instead, which reads `SIGNER_ADDRESS_0`, `SIGNER_ADDRESS_1`, … from the environment.

**Environment variables for `SafeScriptBase`:**

| Variable | Description |
| --- | --- |
| `DEPLOYER_SAFE_ADDRESS` | The Safe address |
| `SIGNER_ADDRESS` | Owner address (single-sig) |
| `SIGNER_ADDRESS_0`, `_1`, … | Owner addresses (multi-sig) |
| `DERIVATION_PATH` | HW wallet path, e.g. `m/44'/60'/0'/0/0` |
| `HARDWARE_WALLET` | `ledger` (default) or `trezor` |
| `SAFE_BROADCAST` | Set to `true` to force broadcast mode |

### Requirements

- Foundry with FFI enabled:
  - Pass `--ffi` to your commands (e.g. `forge test --ffi`)
  - Or set `ffi = true` in your `foundry.toml`

```toml
[profile.default]
ffi = true
```

- All `Recon-Fuzz/solidity-http` dependencies

### Tests

Run `npm ci` and `forge test` from the repository root. Some tests read Base through its public RPC. Signature validation and the additional hash tests also deploy Safes locally, so those checks do not require an RPC connection.

The two tests that submit proposals to the live Transaction Service are skipped by default. To run them explicitly against the repository's test Safe:

```bash
SAFE_UTILS_LIVE_API_TESTS=true forge test --match-test 'test_Safe_propose'
```

This command writes proposals to the service. It does not broadcast on-chain transactions.

### Third-party integrations

The following blockchains are integrated via third-party APIs and not the official `safe.global` tx service:

| Blockchain | Provider |
| --- | --- |
| [Plume](https://plume.org/) | [OnChainDen](https://onchainden.com/) |

### Demo

https://github.com/Recon-Fuzz/governance-proposals-done-right

### Disclaimer

This code is provided "as is" and has not undergone a formal security audit.

Use it at your own risk. The author(s) assume no liability for any damages or losses resulting from the use of this code. It is your responsibility to thoroughly review, test, and validate its security and functionality before deploying or relying on it in any environment.

This is not an official [@safe-global](https://github.com/safe-global) library
