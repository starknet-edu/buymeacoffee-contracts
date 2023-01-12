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