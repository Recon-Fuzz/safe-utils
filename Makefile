# Load environment variables from .env file
include .env

.PHONY: anvil build clean coverage deploy dev fork format fund help install snapshot test

# Clean the environment
clean:
	forge clean

# Remove modules
remove :
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install Dependencies
install:
	forge install cyfrin/foundry-devops --no-commit && forge install smartcontractkit/chainlink-brownie-contracts --no-commit && forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:
	forge update

# Build contracts
build:
	forge build

# Execute tests
test:
	forge test 

# Test Coverage
coverage:
	forge coverage --report debug > coverage-report.txt

# Gas Snapshot
snapshot:
	forge snapshot

format:
	forge fmt

# Initialize forked network with anvil
fork:
	anvil --fork-url $(CHAIN_RPC_URL)

# Generate Keys
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 

NETWORK_ARGS := --rpc-url http://localhost:8545 --account $(LOCAL_KEY) --broadcast

# Change Args if is sepolia - Update according to your needs
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Deploy contract
deploy:
	@forge script script/Deploy.s.sol:DeployScript $(NETWORK_ARGS)
