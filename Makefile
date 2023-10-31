-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_GANACHE_KEY := 0x86529f838795b4af21d0e78f29194d3411d7e1402cd978001f034ced98d49156

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make shareNews [ARGS=...]\n    example: make shareNews ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.0.11 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
ifeq ($(findstring ganache,$(NET)), ganache)
	NETWORK_ARGS := --rpc-url http://localhost:7545 --private-key $(DEFAULT_GANACHE_KEY) --broadcast
endif

# ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
# 	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# endif

deploy:
	@forge script script/DeployScript.s.sol:DeployScript $(NETWORK_ARGS)

shareNews:
	@forge script script/InteractionsNewsSharing.s.sol:ShareNews --sig "run(string, string, string, uint)" $(ARGS) $(NETWORK_ARGS)

getNews:
	@forge script script/InteractionsNewsSharing.s.sol:GetNews --sig "run(uint)" $(ARGS) $(NETWORK_ARGS)

startNewsValidation:
	@forge script script/InteractionsNewsEvaluation.s.sol:StartNewsValidation --sig "run(uint)" $(ARGS) $(NETWORK_ARGS)

evaluateNews:
	@forge script script/InteractionsNewsEvaluation.s.sol:EvaluateNews --sig "run(uint, bool, uint)" $(ARGS) $(NETWORK_ARGS)

getNewsValidation:
	@forge script script/InteractionsNewsEvaluation.s.sol:GetNewsValidation --sig "run(uint)" $(ARGS) $(NETWORK_ARGS)
