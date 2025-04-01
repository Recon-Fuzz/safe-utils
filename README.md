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

### Requirements

- Foundry with FFI enabled:
  - Pass `--ffi` to your commands (e.g. `forge test --ffi`)
  - Or set `ffi = true` in your `foundry.toml`

```toml
[profile.default]
ffi = true
```

- All `Recon-Fuzz/solidity-http` dependencies
