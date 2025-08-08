use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::testing::{set_caller_address, set_block_timestamp, set_contract_address};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::world::WorldStorageTrait;
use dojo::utils::test::{spawn_test_world, deploy_contract};
use coa::models::tournament::{
    Tournament, TournamentType, TournamentStatus, Participant, Match, Winner, Config, Errors,
    TournamentCreated, PlayerRegistered, PlayerUnregistered, TournamentStarted,
    TournamentCancelled, MatchCompleted, TournamentFinished, PrizeClaimed,
};
use coa::models::player::{Player};
use coa::models::session::SessionKey;
use coa::systems::tournament::{TournamentActions, ITournament, ITournamentDispatcher, ITournamentDispatcherTrait};

// Mock ERC1155 contract for testing
#[starknet::contract]
mod MockERC1155 {
    use starknet::ContractAddress;
    use openzeppelin::token::erc1155::interface::IERC1155;
    
    #[storage]
    struct Storage {
        balances: LegacyMap<(u256, ContractAddress), u256>,
    }
    
    #[abi(embed_v0)]
    impl IERC1155Impl of IERC1155<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
            self.balances.read((id, account))
        }
        
        fn balance_of_batch(
            self: @ContractState, accounts: Span<ContractAddress>, ids: Span<u256>
        ) -> Span<u256> {
            array![].span()
        }
        
        fn is_approved_for_all(
            self: @ContractState, account: ContractAddress, operator: ContractAddress
        ) -> bool {
            true
        }
        
        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {}
        
        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            id: u256,
            value: u256,
            data: Span<felt252>
        ) {
            // Mock implementation - just update balances
            let current_balance = self.balances.read((id, from));
            self.balances.write((id, from), current_balance - value);
            let recipient_balance = self.balances.read((id, to));
            self.balances.write((id, to), recipient_balance + value);
        }
        
        fn safe_batch_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>
        ) {}
    }
}

fn setup_world() -> (dojo::world::WorldStorage, ITournamentDispatcher) {
    let mut models = array![
        Tournament::TEST_CLASS_HASH,
        Config::TEST_CLASS_HASH,
        Participant::TEST_CLASS_HASH,
        Match::TEST_CLASS_HASH,
        Winner::TEST_CLASS_HASH,
        Player::TEST_CLASS_HASH,
        SessionKey::TEST_CLASS_HASH,
    ];
    
    let world = spawn_test_world(models);
    let contract_address = deploy_contract(TournamentActions::TEST_CLASS_HASH, array![]);
    
    (world, ITournamentDispatcher { contract_address })
}

fn setup_mock_erc1155() -> ContractAddress {
    deploy_contract(MockERC1155::TEST_CLASS_HASH, array![])
}

fn create_test_player(world: dojo::world::WorldStorage, address: ContractAddress, level: u256) {
    let player = Player {
        player_address: address,
        level,
        score: 1000,
        games_played: 10,
        games_won: 5,
    };
    world.write_model(@player);
}

fn create_test_session(world: dojo::world::WorldStorage, session_id: felt252, player_address: ContractAddress) {
    let session = SessionKey {
        session_id,
        player_address,
        expires_at: starknet::get_block_timestamp() + 3600, // 1 hour from now
        last_used: starknet::get_block_timestamp(),
        is_valid: true,
        status: 0,
        max_transactions: 100,
        used_transactions: 0,
    };
    world.write_model(@session);
}

#[test]
fn test_init_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let credit_token_id = 1_u256;
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, credit_token_id);
    
    let config: Config = world.read_model(0);
    assert(config.admin == admin, 'Admin not set correctly');
    assert(config.erc1155_address == mock_erc1155, 'ERC1155 address incorrect');
    assert(config.credit_token_id == credit_token_id, 'Credit token ID incorrect');
    assert(config.next_tournament_id == 1, 'Next tournament ID incorrect');
}

#[test]
#[should_panic(expected: ('Already initialized',))]
fn test_init_already_initialized() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    // Initialize config manually
    let config = Config {
        id: 0,
        admin,
        next_tournament_id: 1,
        erc1155_address: mock_erc1155,
        credit_token_id: 1,
    };
    world.write_model(@config);
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
}

#[test]
fn test_set_admin_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let new_admin = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    tournament.set_admin(new_admin);
    
    let config: Config = world.read_model(0);
    assert(config.admin == new_admin, 'New admin not set correctly');
}

#[test]
#[should_panic(expected: ('NOT_ADMIN',))]
fn test_set_admin_not_admin() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let unauthorized = contract_address_const::<0x789>();
    let new_admin = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(unauthorized);
    tournament.set_admin(new_admin);
}

#[test]
fn test_create_tournament_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(creator);
    set_block_timestamp(1000);
    
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.id == 1, 'Tournament ID incorrect');
    assert(tournament_data.creator == creator, 'Creator incorrect');
    assert(tournament_data.name == 'Test Tournament', 'Name incorrect');
    assert(tournament_data.status == TournamentStatus::Open, 'Status incorrect');
    assert(tournament_data.prize_pool == 1000, 'Prize pool incorrect');
    assert(tournament_data.entry_fee == 100, 'Entry fee incorrect');
    assert(tournament_data.max_players == 8, 'Max players incorrect');
    assert(tournament_data.min_players == 4, 'Min players incorrect');
}

#[test]
#[should_panic(expected: ('INVALID_DATES',))]
fn test_create_tournament_invalid_dates() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        2000_u64, // registration_start > registration_end
        1500_u64,
        5_u256
    );
}

#[test]
#[should_panic(expected: ('INVALID_PLAYERS',))]
fn test_create_tournament_invalid_players_min_too_low() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        1_u32, // min_players < 2
        1100_u64,
        2000_u64,
        5_u256
    );
}

#[test]
#[should_panic(expected: ('INVALID_PLAYERS',))]
fn test_create_tournament_invalid_players_min_greater_than_max() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        4_u32,
        8_u32, // min_players > max_players
        1100_u64,
        2000_u64,
        5_u256
    );
}

#[test]
#[should_panic(expected: ('REGISTRATION_END_MUST_BE_IN_FUTURE',))]
fn test_create_tournament_registration_end_in_past() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(2500);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64, // registration_end < current time
        5_u256
    );
}

#[test]
#[should_panic(expected: ('LOW_PRIZE_POOL',))]
fn test_create_tournament_low_prize_pool() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        200_u256, // prize_pool < min_players * entry_fee (4 * 100 = 400)
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
}

#[test]
fn test_register_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    // Setup
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Create player with sufficient level
    create_test_player(world, player, 10_u256);
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, session_id);
    
    let participant: Participant = world.read_model((1_u256, player));
    assert(participant.is_registered, 'Player not registered');
    assert(participant.tournament_id == 1, 'Tournament ID incorrect');
    assert(participant.player_id == player, 'Player ID incorrect');
    
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.registered_players == 1, 'Registered players count incorrect');
}

#[test]
#[should_panic(expected: ('INVALID_SESSION',))]
fn test_register_invalid_session() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    create_test_player(world, player, 10_u256);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, 0); // Invalid session_id (zero)
}

#[test]
#[should_panic(expected: ('REG_WINDOW_CLOSED',))]
fn test_register_window_closed() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    create_test_player(world, player, 10_u256);
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(2500); // After registration window
    tournament.register(1_u256, session_id);
}

#[test]
#[should_panic(expected: ('LEVEL_TOO_LOW',))]
fn test_register_level_too_low() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        10_u256 // Level requirement: 10
    );
    
    create_test_player(world, player, 5_u256); // Player level: 5 (too low)
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, session_id);
}

#[test]
#[should_panic(expected: ('ALREADY_REGISTERED',))]
fn test_register_already_registered() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    create_test_player(world, player, 10_u256);
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, session_id);
    tournament.register(1_u256, session_id); // Try to register again
}

#[test]
fn test_unregister_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    // Setup and register player first
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    create_test_player(world, player, 10_u256);
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, session_id);
    
    // Now unregister
    tournament.unregister(1_u256, session_id);
    
    let participant: Participant = world.read_model((1_u256, player));
    assert(!participant.is_registered, 'Player should be unregistered');
    
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.registered_players == 0, 'Registered players count should be 0');
}

#[test]
#[should_panic(expected: ('NOT_REGISTERED',))]
fn test_unregister_not_registered() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    create_test_player(world, player, 10_u256);
    create_test_session(world, session_id, player);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.unregister(1_u256, session_id); // Try to unregister without registering first
}

#[test]
fn test_cancel_tournament_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(creator);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    let registered_players = array![];
    tournament.cancel_tournament(1_u256, registered_players);
    
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.status == TournamentStatus::Cancelled, 'Tournament should be cancelled');
}

#[test]
#[should_panic(expected: ('NOT_CREATOR',))]
fn test_cancel_tournament_not_creator() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    let other_user = contract_address_const::<0x789>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(creator);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    set_caller_address(other_user);
    let registered_players = array![];
    tournament.cancel_tournament(1_u256, registered_players);
}

#[test]
fn test_start_tournament_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    let player1 = contract_address_const::<0x111>();
    let player2 = contract_address_const::<0x222>();
    let player3 = contract_address_const::<0x333>();
    let player4 = contract_address_const::<0x444>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(creator);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        0_u256, // No entry fee for simplicity
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Register 4 players
    let players = array![player1, player2, player3, player4];
    let mut i = 0;
    loop {
        if i >= players.len() {
            break;
        }
        let player = *players.at(i);
        create_test_player(world, player, 10_u256);
        create_test_session(world, 'session', player);
        
        set_caller_address(player);
        set_block_timestamp(1500);
        tournament.register(1_u256, 'session');
        
        // Register participants manually for tournament start
        let participant = Participant {
            tournament_id: 1_u256,
            player_id: player,
            is_registered: true,
            matches_played: 0,
            matches_won: 0,
            is_eliminated: false,
        };
        world.write_model(@participant);
        
        i += 1;
    };
    
    // Update tournament registered players count
    let mut tournament_data: Tournament = world.read_model(1_u256);
    tournament_data.registered_players = 4;
    world.write_model(@tournament_data);
    
    set_caller_address(creator);
    tournament.start_tournament(1_u256, players);
    
    let updated_tournament: Tournament = world.read_model(1_u256);
    assert(updated_tournament.status == TournamentStatus::InProgress, 'Tournament should be in progress');
}

#[test]
#[should_panic(expected: ('NOT_ENOUGH_PLAYERS',))]
fn test_start_tournament_not_enough_players() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(creator);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32, // Minimum 4 players required
        1100_u64,
        2000_u64,
        5_u256
    );
    
    let participants = array![]; // Empty participants list
    tournament.start_tournament(1_u256, participants);
}

#[test]
fn test_calculate_rounds() {
    let (world, tournament) = setup_world();
    
    // Test edge cases and various player counts
    // Assuming we need to test the internal calculate_rounds function
    // Since it's internal, we'll test it indirectly through tournament creation
    
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_caller_address(admin);
    set_block_timestamp(1000);
    
    // Test with 4 players (should be 2 rounds)
    tournament.create_tournament(
        'Test Tournament 4',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        4_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.total_rounds == 2, 'Should be 2 rounds for 4 players');
    
    // Test with 8 players (should be 3 rounds)
    tournament.create_tournament(
        'Test Tournament 8',
        TournamentType::SingleElimination,
        2000_u256,
        100_u256,
        8_u32,
        8_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    let tournament_data_8: Tournament = world.read_model(2_u256);
    assert(tournament_data_8.total_rounds == 3, 'Should be 3 rounds for 8 players');
}

#[test]
fn test_claim_prize_success() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let winner = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    // Create a winner record manually
    let winner_record = Winner {
        tournament_id: 1_u256,
        player_id: winner,
        placement: 1,
        prize_amount: 1000_u256,
        has_claimed: false,
    };
    world.write_model(@winner_record);
    
    create_test_session(world, session_id, winner);
    
    set_caller_address(winner);
    tournament.claim_prize(1_u256, session_id);
    
    let updated_winner: Winner = world.read_model((1_u256, winner));
    assert(updated_winner.has_claimed, 'Prize should be claimed');
}

#[test]
#[should_panic(expected: ('NOT_WINNER',))]
fn test_claim_prize_not_winner() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let non_winner = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    create_test_session(world, session_id, non_winner);
    
    set_caller_address(non_winner);
    tournament.claim_prize(1_u256, session_id); // No winner record exists
}

#[test]
#[should_panic(expected: ('PRIZE_CLAIMED',))]
fn test_claim_prize_already_claimed() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let winner = contract_address_const::<0x456>();
    let session_id = 'session1';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    // Create a winner record that has already claimed
    let winner_record = Winner {
        tournament_id: 1_u256,
        player_id: winner,
        placement: 1,
        prize_amount: 1000_u256,
        has_claimed: true, // Already claimed
    };
    world.write_model(@winner_record);
    
    create_test_session(world, session_id, winner);
    
    set_caller_address(winner);
    tournament.claim_prize(1_u256, session_id);
}

#[test]
#[should_panic(expected: ('SESSION_EXPIRED',))]
fn test_validate_session_expired() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'expired_session';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Create expired session
    let expired_session = SessionKey {
        session_id,
        player_address: player,
        expires_at: 500_u64, // Expired
        last_used: 400_u64,
        is_valid: true,
        status: 0,
        max_transactions: 100,
        used_transactions: 0,
    };
    world.write_model(@expired_session);
    
    create_test_player(world, player, 10_u256);
    
    set_caller_address(player);
    set_block_timestamp(1500); // Current time > expires_at
    tournament.register(1_u256, session_id);
}

#[test]
#[should_panic(expected: ('NO_TRANSACTIONS_LEFT',))]
fn test_validate_session_no_transactions_left() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'no_tx_session';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Create session with no transactions left
    let no_tx_session = SessionKey {
        session_id,
        player_address: player,
        expires_at: starknet::get_block_timestamp() + 3600,
        last_used: starknet::get_block_timestamp(),
        is_valid: true,
        status: 0,
        max_transactions: 10,
        used_transactions: 10, // All transactions used
    };
    world.write_model(@no_tx_session);
    
    create_test_player(world, player, 10_u256);
    
    set_caller_address(player);
    set_block_timestamp(1500);
    tournament.register(1_u256, session_id);
}

#[test]
fn test_session_auto_renewal() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let player = contract_address_const::<0x456>();
    let session_id = 'auto_renew_session';
    
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        100_u256,
        8_u32,
        4_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Create session that expires in 2 minutes (less than 5 minutes)
    set_block_timestamp(1500);
    let current_time = starknet::get_block_timestamp();
    let short_expiry_session = SessionKey {
        session_id,
        player_address: player,
        expires_at: current_time + 120, // 2 minutes from now
        last_used: current_time,
        is_valid: true,
        status: 0,
        max_transactions: 10,
        used_transactions: 5,
    };
    world.write_model(@short_expiry_session);
    
    create_test_player(world, player, 10_u256);
    
    set_caller_address(player);
    tournament.register(1_u256, session_id);
    
    // Check that session was auto-renewed
    let renewed_session: SessionKey = world.read_model((session_id, player));
    assert(renewed_session.expires_at == current_time + 3600, 'Session should be renewed for 1 hour');
    assert(renewed_session.max_transactions == 100, 'Should have 100 transactions');
    assert(renewed_session.used_transactions == 1, 'Should have 1 used transaction');
}

#[test]
fn test_tournament_flow_integration() {
    let (mut world, tournament) = setup_world();
    let mock_erc1155 = setup_mock_erc1155();
    let admin = contract_address_const::<0x123>();
    let creator = contract_address_const::<0x456>();
    let player1 = contract_address_const::<0x111>();
    let player2 = contract_address_const::<0x222>();
    
    // Initialize system
    set_caller_address(admin);
    tournament.init(mock_erc1155, 1_u256);
    
    // Create tournament
    set_caller_address(creator);
    set_block_timestamp(1000);
    tournament.create_tournament(
        'Integration Test Tournament',
        TournamentType::SingleElimination,
        1000_u256,
        0_u256, // No entry fee
        4_u32,
        2_u32,
        1100_u64,
        2000_u64,
        5_u256
    );
    
    // Register players
    create_test_player(world, player1, 10_u256);
    create_test_player(world, player2, 15_u256);
    create_test_session(world, 'session1', player1);
    create_test_session(world, 'session2', player2);
    
    set_block_timestamp(1500);
    
    set_caller_address(player1);
    tournament.register(1_u256, 'session1');
    
    set_caller_address(player2);
    tournament.register(1_u256, 'session2');
    
    // Verify registrations
    let tournament_data: Tournament = world.read_model(1_u256);
    assert(tournament_data.registered_players == 2, 'Should have 2 registered players');
    
    // Start tournament
    let participants = array![player1, player2];
    set_caller_address(creator);
    tournament.start_tournament(1_u256, participants);
    
    let started_tournament: Tournament = world.read_model(1_u256);
    assert(started_tournament.status == TournamentStatus::InProgress, 'Tournament should be in progress');
}