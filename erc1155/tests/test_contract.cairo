use starknet::{ContractAddress, contract_address_const};
use erc1155::IERC1155::{
    ICitizenArcanisERC1155Dispatcher as IERC1155Dispatcher, ICitizenArcanisERC1155DispatcherTrait,
};
use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use erc1155::utils::{
    CREDITS, CHEST_ARMOR, WEAPON_1, BOOTS, HANDGUN_AMMO, MACHINE_GUN_AMMO, PET_1, VEHICLE,
};

fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn zero() -> ContractAddress {
    contract_address_const::<0>()
}

fn account1() -> ContractAddress {
    contract_address_const::<'kim'>()
}

fn account2() -> ContractAddress {
    contract_address_const::<'thurston'>()
}

fn account3() -> ContractAddress {
    contract_address_const::<'lee'>()
}

fn deploy() -> ContractAddress {
    let owner = owner();
    let base_uri: ByteArray = "ipfs://initial/";
    let contract = declare("CitizenArcanisERC1155")
        .expect('Contract declaration failed')
        .contract_class();

    let mut constructor_calldata = ArrayTrait::new();
    owner.serialize(ref constructor_calldata);
    base_uri.serialize(ref constructor_calldata);

    let (contract_address, _) = contract
        .deploy(@constructor_calldata)
        .expect('Contract deployment failed');

    contract_address
}


// --- Minting Tests ---

#[test]
fn test_mint_nft_success() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    // Set caller to owner
    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(recipient, WEAPON_1);

    assert(erc1155_dispatcher.Balance_of(recipient, WEAPON_1) == 1, 'NFT_balance_mismatch');
    assert(erc1155_dispatcher.Balance_of(owner(), WEAPON_1) == 0, 'Owner_NFT_balance_nonzero');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_mint_nft_fail_not_owner() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    // Set caller to non-owner
    cheat_caller_address(contract_address, account2(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(recipient, WEAPON_1);
}

#[test]
#[should_panic(expected: ('Not_valid_NFT_id',))]
fn test_mint_nft_fail_ft_id() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(recipient, CREDITS);
}

#[test]
#[should_panic(expected: ('account_zero_address',))]
fn test_mint_nft_fail_zero_recipient() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(zero(), WEAPON_1);
}

#[test]
#[should_panic(expected: ('account_already_owns_this_NFT',))]
fn test_mint_nft_fail_already_owned() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(recipient, WEAPON_1);
    erc1155_dispatcher.mint_NFT(recipient, WEAPON_1);
}

#[test]
fn test_mint_ft_success() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_FT(recipient, CREDITS, 100);

    assert(erc1155_dispatcher.Balance_of(recipient, CREDITS) == 100, 'FT balance mismatch');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_mint_ft_fail_not_owner() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };

    cheat_caller_address(contract_address, account2(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_FT(account1(), CREDITS, 100);
}

#[test]
#[should_panic(expected: ('token_id_formate_of_NFT',))]
fn test_mint_ft_fail_nft_id() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_FT(account1(), WEAPON_1, 100);
}

#[test]
#[should_panic(expected: ('amount_must_>0',))]
fn test_mint_ft_fail_zero_amount() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_FT(account1(), CREDITS, 0);
}

#[test]
fn test_batch_mint_success() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    let ids = array![CREDITS, CHEST_ARMOR, HANDGUN_AMMO, PET_1].span();
    let values = array![100, 1, 100, 1].span();
    let data = array![].span();

    erc1155_dispatcher.Batch_mint(recipient, ids, values, data);

    assert(erc1155_dispatcher.Balance_of(recipient, *ids[0]) == 100, 'mint FT1 balance_100');
    assert(erc1155_dispatcher.Balance_of(recipient, *ids[1]) == 1, 'mint NFT1 balance_1');
    assert(erc1155_dispatcher.Balance_of(recipient, *ids[2]) == 100, 'Batch mint FT2 balance_100');
    assert(erc1155_dispatcher.Balance_of(recipient, *ids[3]) == 1, 'Batch mint NFT2 balance_1');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_batch_mint_fail_not_owner() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, account2(), CheatSpan::TargetCalls(1));

    let ids = array![CREDITS, CHEST_ARMOR, HANDGUN_AMMO, PET_1].span();
    let values = array![100, 1, 100, 1].span();
    let data = array![].span();

    erc1155_dispatcher.Batch_mint(recipient, ids, values, data);
}

#[test]
#[should_panic(expected: ('length_mismatch',))]
fn test_batch_mint_fail_length_mismatch() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    let ids = array![CREDITS, CHEST_ARMOR, HANDGUN_AMMO, PET_1].span();
    let values = array![100, 1, 100, 1, 100].span();
    let data = array![].span();

    erc1155_dispatcher.Batch_mint(recipient, ids, values, data);
}

#[test]
#[should_panic(expected: ('account_zero_address',))]
fn test_batch_mint_fail_zero_recipient() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = zero();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    let ids = array![CREDITS, CHEST_ARMOR, HANDGUN_AMMO, PET_1].span();
    let values = array![100, 1, 100, 1].span();
    let data = array![].span();

    erc1155_dispatcher.Batch_mint(recipient, ids, values, data);
}
// // --- Approval Tests ---
// #[test]
// fn test_set_approval_for_all() {
//     let (contract_address, dispatcher) = setup();
//     let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
//     let owner_addr = account1(); // Use account1 as the owner for this test
//     let operator_addr = operator();

//     testing::set_caller_address(owner_addr);

//     // Check initial state
//     assert(
//         !erc1155_dispatcher.is_approved_for_all(owner_addr, operator_addr), 'Initially approved',
//     );

//     // Approve
//     dispatcher.set_approval_for_all(operator_addr, true);
//     assert(erc1155_dispatcher.is_approved_for_all(owner_addr, operator_addr), 'Approval failed');

//     // Check event
//     // Add event check for ApprovalForAll(owner_addr, operator_addr, true)

//     // Revoke
//     dispatcher.set_approval_for_all(operator_addr, false);
//     assert(!erc1155_dispatcher.is_approved_for_all(owner_addr, operator_addr), 'Revoke failed');
//     // Check event
// // Add event check for ApprovalForAll(owner_addr, operator_addr, false)
// }

// // --- Transfer Tests ---

// #[test]
// fn test_safe_transfer_from_nft_owner() {
//     let (contract_address, dispatcher) = setup();
//     let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
//     let from_addr = account1();
//     let to_addr = account2();

//     // Mint NFT to 'from_addr'
//     testing::set_caller_address(owner());
//     dispatcher.mint_NFT(from_addr, NFT_ID_1);
//     assert(
//         erc1155_dispatcher.balance_of(from_addr, NFT_ID_1) == NFT_AMOUNT, 'Pre-transfer balance',
//     );

//     // Transfer by owner ('from_addr')
//     testing::set_caller_address(from_addr);
//     dispatcher.safe_transfer_from(from_addr, to_addr, NFT_ID_1, NFT_AMOUNT, array![].span());

//     // Check balances
//     assert(
//         erc1155_dispatcher.balance_of(from_addr, NFT_ID_1) == 0,
//         'Sender balance after NFT transfer',
//     );
//     assert(
//         erc1155_dispatcher.balance_of(to_addr, NFT_ID_1) == NFT_AMOUNT,
//         'Receiver balance after NFT transfer',
//     );
//     // Check event (TransferSingle)
// // Add detailed event check here
// }

// #[test]
// fn test_safe_transfer_from_ft_owner() {
//     let (contract_address, dispatcher) = setup();
//     let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
//     let from_addr = account1();
//     let to_addr = account2();
//     let transfer_amount = FT_AMOUNT_1 / 2; // Transfer half

//     // Mint FT to 'from_addr'
//     testing::set_caller_address(owner());
//     dispatcher.mint_FT(from_addr, FT_ID_1, FT_AMOUNT_1);
//     assert(
//         erc1155_dispatcher.balance_of(from_addr, FT_ID_1) == FT_AMOUNT_1, 'Pre-transfer FT
//         balance',
//     );

//     // Transfer by owner ('from_addr')
//     testing::set_caller_address(from_addr);
//     dispatcher.safe_transfer_from(from_addr, to_addr, FT_ID_1, transfer_amount, array![].span());

//     // Check balances
//     assert(
//         erc1155_dispatcher.balance_of(from_addr, FT_ID_1) == (FT_AMOUNT_1 - transfer_amount),
//         'Sender balance after FT transfer',
//     );
//     assert(
//         erc1155_dispatcher.balance_of(to_addr, FT_ID_1) == transfer_amount,
//         'Receiver balance after FT transfer',
//     );
//     // Check event (TransferSingle)
// }

// #[test]
// fn test_safe_transfer_from_operator() {
//     let (contract_address, dispatcher) = setup();
//     let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
//     let owner_addr = account1();
//     let to_addr = account2();
//     let operator_addr = operator();

//     // Mint NFT to 'owner_addr'
//     testing::set_caller_address(owner());
//     dispatcher.mint_NFT(owner_addr, NFT_ID_1);

//     // Approve operator
//     testing::set_caller_address(owner_addr);
//     dispatcher.set_approval_for_all(operator_addr, true);

//     // Transfer by operator
//     testing::set_caller_address(operator_addr);
//     dispatcher.safe_transfer_from(owner_addr, to_addr, NFT_ID_1, NFT_AMOUNT, array![].span());

//     // Check balances
//     assert(erc1155_dispatcher.balance_of(owner_addr, NFT_ID_1) == 0, 'Op: Sender balance');
//     assert(erc1155_dispatcher.balance_of(to_addr, NFT_ID_1) == NFT_AMOUNT, 'Op: Receiver
//     balance');
//     // Check event (TransferSingle)
// }

// #[test]
// #[should_panic(expected: ('ERC1155: insufficient balance',))] // Or similar error from component
// fn test_safe_transfer_from_fail_insufficient_balance() {
//     let (_contract_address, dispatcher) = setup();
//     let from_addr = account1();
//     let to_addr = account2();

//     // Try to transfer NFT that 'from_addr' doesn't have
//     testing::set_caller_address(from_addr);
//     dispatcher.safe_transfer_from(from_addr, to_addr, NFT_ID_1, NFT_AMOUNT, array![].span());
// }

// #[test]
// #[should_panic(
//     expected: ('ERC1155: caller is not owner nor approved',),
// )] // Or similar error from component
// fn test_safe_transfer_from_fail_not_approved() {
//     let (_contract_address, dispatcher) = setup();
//     let owner_addr = account1();
//     let to_addr = account2();
//     let operator_addr = operator(); // The caller trying the transfer

//     // Mint NFT to 'owner_addr'
//     testing::set_caller_address(owner());
//     dispatcher.mint_NFT(owner_addr, NFT_ID_1);

//     // Transfer by unapproved operator
//     testing::set_caller_address(operator_addr);
//     dispatcher.safe_transfer_from(owner_addr, to_addr, NFT_ID_1, NFT_AMOUNT, array![].span());
// }

// // --- Batch Transfer Tests ---
// #[test]
// fn test_safe_batch_transfer_from_owner() {
//     let (contract_address, dispatcher) = setup();
//     let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
//     let from_addr = account1();
//     let to_addr = account2();

//     // Mint tokens to 'from_addr'
//     testing::set_caller_address(owner());
//     let ids_mint = array![NFT_ID_1, FT_ID_1].span();
//     let values_mint = array![NFT_AMOUNT, FT_AMOUNT_1].span();
//     dispatcher.batch_mint(from_addr, ids_mint, values_mint, array![].span());

//     // Check initial balances
//     let accounts_span = array![from_addr, from_addr].span();
//     let initial_balances = erc1155_dispatcher.balance_of_batch(accounts_span, ids_mint);
//     assert(*initial_balances.at(0) == NFT_AMOUNT, 'Initial NFT');
//     assert(*initial_balances.at(1) == FT_AMOUNT_1, 'Initial FT');

//     // Transfer batch
//     testing::set_caller_address(from_addr);
//     let ids_transfer = array![NFT_ID_1, FT_ID_1].span();
//     let amounts_transfer = array![NFT_AMOUNT, FT_AMOUNT_1 / 2].span(); // Transfer NFT and half
//     FT dispatcher
//         .safe_batch_transfer_from(
//             from_addr, to_addr, ids_transfer, amounts_transfer, array![].span(),
//         );

//     // Check final balances (from_addr)
//     let final_balances_from = erc1155_dispatcher.balance_of_batch(accounts_span, ids_mint);
//     assert(*final_balances_from.at(0) == 0, 'Final From NFT');
//     assert(*final_balances_from.at(1) == FT_AMOUNT_1 / 2, 'Final From FT');

//     // Check final balances (to_addr)
//     let accounts_span_to = array![to_addr, to_addr].span();
//     let final_balances_to = erc1155_dispatcher.balance_of_batch(accounts_span_to, ids_mint);
//     assert(*final_balances_to.at(0) == NFT_AMOUNT, 'Final To NFT');
//     assert(*final_balances_to.at(1) == FT_AMOUNT_1 / 2, 'Final To FT');
//     // Check event (TransferBatch)
// // Add detailed event check here
// }

// // Add tests for batch transfer failure cases (insufficient balance, not owner/approved) similar
// to // single transfer

// // --- URI Tests ---
// #[test]
// fn test_set_base_uri() {
//     let contract_address = deploy();

//     // Check initial URI
//     assert(erc1155_dispatcher.Uri(NFT_ID_1) == BASE_URI_INITIAL, 'Initial URI mismatch');

//     // Set new URI as owner
//     testing::set_caller_address(owner());
//     dispatcher.set_base_uri(BASE_URI_NEW);

//     // Check new URI
//     assert(dispatcher.Uri(NFT_ID_1) == BASE_URI_NEW, 'New URI mismatch');
//     assert(
//         dispatcher.Uri(FT_ID_1) == BASE_URI_NEW, 'New URI mismatch FT',
//     ); // Should apply to all token IDs
// }

// #[test]
// #[should_panic(expected: ('Caller is not the owner',))]
// fn test_set_base_uri_fail_not_owner() {
//     let (_contract_address, dispatcher) = setup();

//     // Attempt set URI as non-owner
//     testing::set_caller_address(account1());
//     dispatcher.set_base_uri(BASE_URI_NEW);
// }

// // --- Ownable Tests ---
// #[test]
// fn test_transfer_ownership() {
//     let (contract_address, _dispatcher) = setup();
//     let ownable_dispatcher = IOwnableDispatcher { contract_address };
//     let current_owner = owner();
//     let new_owner = account1();

//     // Check initial owner
//     assert(ownable_dispatcher.owner() == current_owner, 'Initial owner incorrect');

//     // Transfer ownership
//     testing::set_caller_address(current_owner);
//     ownable_dispatcher.transfer_ownership(new_owner);

//     // Check new owner
//     assert(ownable_dispatcher.owner() == new_owner, 'New owner incorrect');
//     // Check event (OwnershipTransferred)
// }

// #[test]
// #[should_panic(expected: ('Caller is not the owner',))]
// fn test_transfer_ownership_fail_not_owner() {
//     let (contract_address, _dispatcher) = setup();
//     let ownable_dispatcher = IOwnableDispatcher { contract_address };
//     let new_owner = account1();

//     // Attempt transfer from non-owner
//     testing::set_caller_address(account2());
//     ownable_dispatcher.transfer_ownership(new_owner);
// }

// #[test]
// fn test_renounce_ownership() {
//     let (contract_address, _dispatcher) = setup();
//     let ownable_dispatcher = IOwnableDispatcher { contract_address };
//     let current_owner = owner();

//     testing::set_caller_address(current_owner);
//     ownable_dispatcher.renounce_ownership();

//     assert(ownable_dispatcher.owner() == zero_address(), 'Owner not renounced');
//     // Check event (OwnershipTransferred to zero address)
// }

// #[test]
// #[should_panic(expected: ('Caller is not the owner',))]
// fn test_renounce_ownership_fail_not_owner() {
//     let (contract_address, _dispatcher) = setup();
//     let ownable_dispatcher = IOwnableDispatcher { contract_address };

//     testing::set_caller_address(account1()); // Not the owner
//     ownable_dispatcher.renounce_ownership();
// }


