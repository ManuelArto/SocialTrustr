-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# (0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 - 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# (1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d - 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
# (2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a - 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
# (3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 - 0x90F79bf6EB2c4f870365E785982E1f101E93b906
# (4) 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a - 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
# (5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba - 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
DEFAULT_GANACHE_KEY := 0x6377edc0e87761edad999e3cb2e0c17cf82c096dffa37ce3c55ddc04df4fef0e

help:
	@echo "Usage:"
	@echo "  make deploy [NETWORK_ARGS=...]\n    example: make deploy NETWORK_ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make shareContent [ARGS=...]\n    example: make shareContent ARGS='Title ipfsCID ChatName 0'"

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

# CONTENT SHARING
shareContent:
	@forge script script/InteractionsContentSharing.s.sol:ContentSharingInteractions --sig "shareContent(string, string, string, uint)" $(ARGS) $(NETWORK_ARGS)

getContent:
	@forge script script/InteractionsContentSharing.s.sol:ContentSharingInteractions --sig "getContent(uint)" $(ARGS) $(NETWORK_ARGS)

getTotalContents:
	@forge script script/InteractionsContentSharing.s.sol:ContentSharingInteractions --sig "getTotalContents()" $(NETWORK_ARGS)

# CONTENT EVALUATION
evaluateContent:
	@forge script script/InteractionsContentEvaluation.s.sol:ContentEvaluationInteractions --sig "evaluateContent(uint, bool, uint)" $(ARGS) $(NETWORK_ARGS)

getContentValidation:
	@forge script script/InteractionsContentEvaluation.s.sol:ContentEvaluationInteractions --sig "getContentValidation(uint)" $(ARGS) $(NETWORK_ARGS)

closeContentValidation:
	@forge script script/InteractionsContentEvaluation.s.sol:ContentEvaluationInteractions --sig "closeContentValidation(uint)" $(ARGS) $(NETWORK_ARGS)

checkContentValidation:
	@forge script script/InteractionsContentEvaluation.s.sol:ContentEvaluationInteractions --sig "checkContentValidation(uint)" $(ARGS) $(NETWORK_ARGS)

# TRUST TOKEN
buyBadge:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "buyBadge()" $(NETWORK_ARGS)

getInfos:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "getInfos()" $(NETWORK_ARGS)

getInfosOf:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "getInfos(address)" $(ARGS) $(NETWORK_ARGS)

sellTrustToken:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "sellTrustToken(uint)" $(ARGS) $(NETWORK_ARGS)

transferTrs:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "transferTrs(address,uint)" $(ARGS) $(NETWORK_ARGS)

buyFromFunds:
	@forge script script/InteractionsTrustToken.s.sol:TrustTokenInteractions --sig "buyFromFunds(uint)" $(ARGS) $(NETWORK_ARGS)