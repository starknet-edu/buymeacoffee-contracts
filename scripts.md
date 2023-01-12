## Install Dependencies
protostar install OpenZeppelin/cairo-contracts@v0.6.0

## Build Contrats
protostar build --cairo-path ./lib/cairo_contracts/src

## Deploy Contracts
export STARKNET_NETWORK=alpha-goerli2
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
protostar -p testnet2 declare ./build/BuyMeACoffee.json --account-address 0x07bcabe962aa18db948bb8619fbdc36ef7681cc4d1e280c78e9c8709402a03db --private-key-path ./.pkey --max-fee auto
protostar -p testnet2 deploy 0x0120f65c4691e12ebe458bb4e19270dc6d5a5a4da2fe6d400f160c4e42a2aaed --account-address 0x07bcabe962aa18db948bb8619fbdc36ef7681cc4d1e280c78e9c8709402a03db --private-key-path ./.pkey --max-fee auto -i 2087021424722619777119509474943472645767659996348769578120564519014510906823 3499543678944654077127082351807638778708609603227051897192898109492058260443







