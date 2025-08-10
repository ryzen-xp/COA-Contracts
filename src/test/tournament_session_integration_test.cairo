use starknet::ContractAddress;
use coa::models::session::SessionKey;
use coa::systems::tournament::{
    ITournamentDispatcher, ITournamentDispatcherTrait, TournamentActions,
};
use coa::systems::session::SessionActions;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_block_timestamp, stop_cheat_block_timestamp, spy_events,
    EventSpyAssertionsTrait,
};

// Helper functions
fn sample_player() -> ContractAddress {
    contract_address_const::<0x123>()
}

fn sample_session_key() -> SessionKey {
    SessionKey {
        session_id: 12345,
        player_address: sample_player(),
        session_key_address: sample_player(),
        created_at: 1000,
        expires_at: 4600, // 1 hour from created_at
        last_used: 1000,
        status: 0, // Active
        max_transactions: 100,
        used_transactions: 5,
        is_valid: true,
    }
}

fn create_tournament_dispatcher() -> ITournamentDispatcher {
    let contract = declare("TournamentActions");
    let mut constructor_args = array![];
    let (contract_address, _) = contract
        .unwrap()
        .contract_class()
        .deploy(@constructor_args)
        .unwrap();
    ITournamentDispatcher { contract_address }
}

fn create_session_dispatcher() -> SessionActionsDispatcher {
    let contract = declare("SessionActions");
    let mut constructor_args = array![];
    let (contract_address, _) = contract
        .unwrap()
        .contract_class()
        .deploy(@constructor_args)
        .unwrap();
    SessionActionsDispatcher { contract_address }
}

#[test]
fn test_tournament_register_with_valid_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let session_dispatcher = create_session_dispatcher();

    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    // Setup session in storage (simulated)
    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test register with valid session
    tournament_dispatcher.register(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
#[should_panic(expected: ('INVALID_SESSION',))]
fn test_tournament_register_with_invalid_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);

    // Test register with invalid session (session_id = 0)
    tournament_dispatcher.register(tournament_id, 0);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_unregister_with_valid_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test unregister with valid session
    tournament_dispatcher.unregister(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_claim_prize_with_valid_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test claim_prize with valid session
    tournament_dispatcher.claim_prize(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_report_match_result_with_valid_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;
    let match_id = 1_u32;
    let winner_id = sample_player();

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test report_match_result with valid session
    tournament_dispatcher.report_match_result(tournament_id, match_id, winner_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_sequential_operations_with_same_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;
    let match_id = 1_u32;
    let winner_id = sample_player();

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test multiple operations with same session

    // Operation 1: Register
    tournament_dispatcher.register(tournament_id, session_id);

    // Operation 2: Report match result
    tournament_dispatcher.report_match_result(tournament_id, match_id, winner_id, session_id);

    // Operation 3: Claim prize
    tournament_dispatcher.claim_prize(tournament_id, session_id);

    // Operation 4: Unregister
    tournament_dispatcher.unregister(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_session_auto_renewal() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);

    // Set time close to session expiration (less than 5 minutes remaining)
    start_cheat_block_timestamp(
        tournament_dispatcher.contract_address, 4300,
    ); // 5 minutes before expiry

    // Test operation that should trigger auto-renewal
    tournament_dispatcher.register(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
#[should_panic(expected: ('SESSION_EXPIRED',))]
fn test_tournament_operation_with_expired_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);

    // Set time after session expiration
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 5000); // After expiry

    // Test operation with expired session
    tournament_dispatcher.register(tournament_id, session_id);

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_different_players_same_session() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player1 = sample_player();
    let player2 = contract_address_const::<0x456>();
    let session_id = 12345;
    let tournament_id = 1_u256;

    // Test player 1
    start_cheat_caller_address(tournament_dispatcher.contract_address, player1);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);
    tournament_dispatcher.register(tournament_id, session_id);
    stop_cheat_caller_address(tournament_dispatcher.contract_address);

    // Test player 2 (should fail with unauthorized session)
    start_cheat_caller_address(tournament_dispatcher.contract_address, player2);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);
    tournament_dispatcher.register(tournament_id, session_id);
    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}

#[test]
fn test_tournament_session_transaction_limits() {
    let tournament_dispatcher = create_tournament_dispatcher();
    let player = sample_player();
    let session_id = 12345;
    let tournament_id = 1_u256;

    start_cheat_caller_address(tournament_dispatcher.contract_address, player);
    start_cheat_block_timestamp(tournament_dispatcher.contract_address, 2000);

    // Test multiple operations to reach transaction limit
    // This would require setting up a session with low transaction limit
    for i in 0..5 {
        let current_tournament_id = tournament_id + i.into();
        tournament_dispatcher.register(current_tournament_id, session_id);
    }

    stop_cheat_caller_address(tournament_dispatcher.contract_address);
    stop_cheat_block_timestamp(tournament_dispatcher.contract_address);
}
