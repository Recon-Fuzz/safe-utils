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

If you are using ledger, make sure to pass the derivation path as the last argument:

```solidity
safe.proposeTransaction(weth, abi.encodeCall(IWETH.withdraw, (0)), sender, "m/44'/60'/0'/0/0");
```

Proposing a transaction/transactions using a Ledger will also require pre-computing the signature, due to a (current) limitation with forge.

The first step is to pre-compute the signature:

```solidity
bytes memory signature = safe.sign(weth, abi.encodeCall(IWETH.withdraw, (0)), Enum.Operation.Call, sender, "m/44'/60'/0'/0/0");
```

Note that this call will fail if `forge script` is called with the `--ledger` flag, as that would block this library's contracts from utilising the same device. Instead, pass the Ledger derivation path as an argument to the script.

The second step is to take the value for the returned `bytes` and provide them when proposing the transaction:

```solidity
safe.proposeTransactionWithSignature(weth, abi.encodeCall(IWETH.withdraw, (0)), sender, signature);
```

#### Batch transactions

For proposing multiple transactions together, use `proposeTransactions`:

```solidity
address[] memory targets = new address[](2);
bytes[] memory datas = new bytes[](2);

targets[0] = address(contract1);
datas[0] = abi.encodeCall(Contract1.someFunction, ());

targets[1] = address(contract2);
datas[1] = abi.encodeCall(Contract2.anotherFunction, ());

safe.proposeTransactions(targets, datas, sender, "m/44'/60'/0'/0/0");
```

If you need to pre-compute the signature for batch transactions (e.g., when using a Ledger), you must:

1. Get the target and data for the batch transaction using `getProposeTransactionsTargetAndData`:

```solidity
(address to, bytes memory data) = safe.getProposeTransactionsTargetAndData(targets, datas);
```

2. Sign the transaction with `Enum.Operation.DelegateCall` (not `Call`):

```solidity
bytes memory signature = safe.sign(to, data, Enum.Operation.DelegateCall, sender, "m/44'/60'/0'/0/0");
```

3. Propose the transactions with the signature:

```solidity
safe.proposeTransactionsWithSignature(targets, datas, sender, signature);
```

**Important**: Batch transactions use `DelegateCall` operation to preserve `msg.sender` across sub-calls. Make sure to sign with `Enum.Operation.DelegateCall`, not `Enum.Operation.Call`.

### Requirements

- Foundry with FFI enabled:
  - Pass `--ffi` to your commands (e.g. `forge test --ffi`)
  - Or set `ffi = true` in your `foundry.toml`

```toml
[profile.default]
ffi = true
```

- All `Recon-Fuzz/solidity-http` dependencies

### Demo

https://github.com/Recon-Fuzz/governance-proposals-done-right

### Disclaimer

This code is provided "as is" and has not undergone a formal security audit.

Use it at your own risk. The author(s) assume no liability for any damages or losses resulting from the use of this code. It is your responsibility to thoroughly review, test, and validate its security and functionality before deploying or relying on it in any environment.

This is not an official [@safe-global](https://github.com/safe-global) library
