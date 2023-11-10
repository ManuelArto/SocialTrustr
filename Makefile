-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
# 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_GANACHE_KEY := 0x6377edc0e87761edad999e3cb2e0c17cf82c096dffa37ce3c55ddc04df4fef0e

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make shareNews [ARGS=...]\n    example: make shareNews ARGS=\"--network sepolia\""

all: clean install update build

# Clean the repo
clean  :; forge clean

install :; forge install cyfrin/foundry-devops --no-commit

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

getTotalNews:
	@forge script script/InteractionsNewsSharing.s.sol:GetTotalNews --sig "run()" $(NETWORK_ARGS)

evaluateNews:
	@forge script script/InteractionsNewsEvaluation.s.sol:EvaluateNews --sig "run(uint, bool, uint)" $(ARGS) $(NETWORK_ARGS)

buyBadge:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "buyBadge()" $(NETWORK_ARGS)

getBalances:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "getBalances()" $(NETWORK_ARGS)

sellTrustToken:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "sellTrustToken(uint)" $(ARGS) $(NETWORK_ARGS)

buyFromFunds:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "buyFromFunds(uint)" $(ARGS) $(NETWORK_ARGS)