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
