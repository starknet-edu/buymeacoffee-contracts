# How to Build "Buy Me a Coffee" DeFi dapp

## Prerequisites
To prepare for the rest of this tutorial, you need to have:
- protostar (0.9.0 or above)
- cairo-lang (0.10.3)

To install the cairo environment, please reference the [documentation](https://starknet.io/docs/quickstart.html#quickstart).

## Code the BuyMeACoffee.cairo smart contract
We will be using **protostar** to:

- generate the project template
- deploy to the Goerli testnet-2 network

To init a cairo project, we will use
```shell
protostar init
```

Then, we needs to change the project structure like this (I'm using tree to visualize):
```shell
.
├── README.md
├── contracts
└── protostar.toml
```
The important folders and files are:
- **contracts** - folder where your smart contracts live
	- in this project we'll only create one, to organize our **BuyMeACoffee** logic
- **protostar.toml** - configuration file with settings for protostar version and deployment

### Coding the main contract:

The main contract should be like this:
```
%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (Uint256, uint256_le)
from openzeppelin.access.ownable.library import Ownable
from contracts.IERC20 import IERC20

@storage_var
func token_address_storage() -> (res: felt) {
}

@event
func buy_me_a_coffee_success(account: felt, name:felt, messages_len:felt, messages: felt*) {
}


@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, owner: felt
) {
    token_address_storage.write(token_address);
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//
@view
func get_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    token_address:felt
) {
    let (token_address) = token_address_storage.read();
    return (token_address,);
}

@external
func buy_me_a_coffee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, messages_len: felt, messages: felt*, amount: Uint256
) {
    alloc_locals;
    let min_amount = Uint256(1000000000000000, 0);//The minimum price should be 0.001ETH
    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (token_address) = token_address_storage.read();
    let (allowance_amount) =IERC20.allowance(token_address, caller_address, contract_address);

    with_attr error_message("This address is not approved. Please approve first") {
        let (is_approved) = uint256_le(min_amount, allowance_amount);
        assert is_approved = 1;
    }

    with_attr error_message("The minimum amout of ETH is 0.001") {
        let (has_token_enough) = uint256_le(min_amount, amount);
        assert has_token_enough = 1;
    }

    let (is_success) = IERC20.transferFrom(token_address, caller_address, contract_address, amount);

    with_attr error_message("Unable to buy me a coffee") {
        assert is_success = 1;
    }

    buy_me_a_coffee_success.emit(caller_address, name, messages_len, messages);
    return ();
}

@external
func withdraw_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}()->(
    amount: Uint256
){
    alloc_locals;
    Ownable.assert_only_owner();
    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (token_address) = token_address_storage.read();
    let (total_balance) = IERC20.balanceOf(token_address, contract_address);
    let (is_success) = IERC20.transfer(token_address, caller_address, total_balance);
    with_attr error_message("Unable to withdraw all tokens") {
        assert is_success = 1;
    }
    return (amount = total_balance);
}
```
Take some time to read through the contract comments and see if you can gather what's going on!

I'll list the highlights here:

- When we deploy the contract, the **constructor** saves the address of the owner wallet that can withdraw all the tokens from the contract. Also, it saves the address of the token address that you need to pay for the coffee. Here we use the [ETH](https://testnet-2.starkscan.co/contract/0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7)
- The **buy_me_a_coffee** function is the most important function on the contract. It accepts four strings **name**, **messages_len**, **messages** and **amount**. When visitors call the **buy_me_a_coffee** function, they must approve their ETH first. To approve the ETH, please use [Starkscan](https://testnet-2.starkscan.co/contract/0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7#write-contract). Then the vistiors need to submit their name, messages_len, messages and ethers amount.The ether is then sent to the contract until the owner withdraws all the ethers. For example, if your name is Tom, your messages are "To wish you special joy at the holidays and all year.", and the ether amount is 0.001 ETH, the parameters should be like this:
```
name: 5533549,
messages_len: 2,
messages:[149182122579714039763801732725514113809195245168513903040698155888525468960,152632285919404616233145710347189435731754891960690],
amount:1000000000000000
```
- **withdraw_all** is a function that only the owner can call, and will transfer all the money to the owner account.

### Deploy the BuyMeACoffee smart contract: 

Firstly, we need to update the **protostar.toml**. The file should be like this:
```
[project]
protostar-version = "0.9.0"
lib-path = "lib"

[contracts]
BuyMeACoffee = ["contracts/BuyMeACoffee.cairo"]

[format]
target = ["src", "tests"]
ignore-broken = true

[profile.devnet.project]
gateway-url = "http://127.0.0.1:5050/"
chain-id = 1536727068981429685321

[profile.testnet.project]
network="testnet"

[profile.testnet2.project]
gateway-url = "https://alpha4-2.starknet.io"
chain-id = 393402129659245999442226

["profile.devnet.protostar.deploy"]
gateway-url="http://127.0.0.1:5050/"

["profile.testnet.protostar.deploy"]
network="testnet"

["profile.testnet2.protostar.deploy"]
gateway-url = "https://alpha4-2.starknet.io"

["profile.mainnet.protostar.deploy"]
network="mainnet"
```
Then, we can deploy the contracts, the scripts of the deployment is shown below:
```
## Install Dependencies
protostar install OpenZeppelin/cairo-contracts@v0.6.0

## Build Contrats
protostar build --cairo-path ./lib/cairo_contracts/src

## Deploy Contracts
export STARKNET_NETWORK=alpha-goerli2
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
protostar -p testnet2 declare ./build/BuyMeACoffee.json --account-address 0x07bcabe962aa18db948bb8619fbdc36ef7681cc4d1e280c78e9c8709402a03db --private-key-path ./.pkey --max-fee auto
protostar -p testnet2 deploy 0x0120f65c4691e12ebe458bb4e19270dc6d5a5a4da2fe6d400f160c4e42a2aaed --account-address 0x07bcabe962aa18db948bb8619fbdc36ef7681cc4d1e280c78e9c8709402a03db --private-key-path ./.pkey --max-fee auto -i 2087021424722619777119509474943472645767659996348769578120564519014510906823 3499543678944654077127082351807638778708609603227051897192898109492058260443
```
If all goes well, you should be able to see your contract address logged to the console after a few seconds:
```
Invoke transaction was sent to the Universal Deployer Contract.                                                       
Contract address: 0x05fc624ccf5310e4c58f685b2ac83b81a844aec3efb8e29e372060b4cced665d
Transaction hash: 3046614808540503142011692824674939431400558914406596987399219904880717735294
```
🎉 Congrats! 🎉

You now have a contract deployed to the Goerli testnet-2. You can view the [contract](https://testnet-2.starkscan.co/contract/0x05fc624ccf5310e4c58f685b2ac83b81a844aec3efb8e29e372060b4cced665d#overview]) on the Goerli-2 starkscan blockchain explorer.

