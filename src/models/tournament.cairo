use starknet::ContractAddress;
use core::num::traits::Zero;

/// Enum defining the different types of tournaments available.
#[derive(Drop, Copy, Serde, Debug, PartialEq, Introspect)]
pub enum TournamentType {
    SingleElimination,
}

/// Enum representing the current status of a tournament.
#[derive(Drop, Copy, Serde, Debug, PartialEq, Introspect)]
pub enum TournamentStatus {
    Open, // Open for registration
    InProgress,
    Completed,
    Cancelled,
}

/// A singleton model to store system-wide configuration.
#[dojo::model]
#[derive(Drop, Serde, Debug)]
pub struct Config {
    #[key]
    pub id: u8, // Singleton ID, always 0
    pub admin: ContractAddress,
    pub next_tournament_id: u256,
    pub erc1155_address: ContractAddress,
    pub credit_token_id: u256,
}

/// The main data model for a tournament.
#[dojo::model]
#[derive(Drop, Copy, Serde, Debug)]
pub struct Tournament {
    #[key]
    pub id: u256,
    pub creator: ContractAddress,
    pub name: felt252,
    pub tournament_type: TournamentType,
    pub status: TournamentStatus,
    pub prize_pool: u256,
    pub entry_fee: u256,
    pub max_players: u32,
    pub min_players: u32,
    pub registration_start: u64,
    pub registration_end: u64,
    pub registered_players: u32,
    pub total_rounds: u32,
    pub level_requirement: u256,
}

/// Represents a player who has registered for a tournament.
#[dojo::model]
#[derive(Drop, Copy, Serde, Debug)]
pub struct Participant {
    #[key]
    pub tournament_id: u256,
    #[key]
    pub player_id: ContractAddress,
    pub is_registered: bool,
    pub matches_played: u32,
    pub matches_won: u32,
    pub is_eliminated: bool,
}

/// Stores information about a single match within a tournament.
#[dojo::model]
#[derive(Drop, Copy, Serde, Debug)]
pub struct Match {
    #[key]
    pub tournament_id: u256,
    #[key]
    pub match_id: u32,
    pub player1: ContractAddress,
    pub player2: Option<ContractAddress>, // Option for bye rounds
    pub winner: ContractAddress,
    pub is_completed: bool,
    pub round: u32,
    pub next_match_id: Option<u32>,
}

/// Records the winners of a tournament and their prize information.
#[dojo::model]
#[derive(Drop, Copy, Serde, Debug)]
pub struct Winner {
    #[key]
    pub tournament_id: u256,
    #[key]
    pub player_id: ContractAddress,
    pub placement: u32,
    pub prize_amount: u256,
    pub has_claimed: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct TournamentCreated {
    #[key]
    pub tournament_id: u256,
    pub creator: ContractAddress,
    pub name: felt252,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerRegistered {
    #[key]
    pub tournament_id: u256,
    pub player_id: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerUnregistered {
    #[key]
    pub tournament_id: u256,
    pub player_id: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct TournamentStarted {
    #[key]
    pub tournament_id: u256,
    pub initial_matches: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct TournamentCancelled {
    #[key]
    pub tournament_id: u256,
    pub refunds_processed: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct MatchCompleted {
    #[key]
    pub tournament_id: u256,
    pub match_id: u32,
    pub winner_id: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct TournamentFinished {
    #[key]
    pub tournament_id: u256,
    pub winner: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PrizeClaimed {
    #[key]
    pub tournament_id: u256,
    #[key]
    pub player_id: ContractAddress,
    pub amount: u256,
}

impl ContractAddressDefault of Default<ContractAddress> {
    fn default() -> ContractAddress {
        Zero::zero()
    }
}

pub mod Errors {
    pub const NOT_ADMIN: felt252 = 'Caller is not the admin';
    pub const NOT_CREATOR: felt252 = 'Not the tournament creator';
    pub const INVALID_DATES: felt252 = 'Invalid registration dates';
    pub const INVALID_PLAYERS: felt252 = 'Invalid min/max players';
    pub const NOT_OPEN: felt252 = 'Tournament not open';
    pub const ALREADY_STARTED: felt252 = 'Tournament already started';
    pub const NOT_ENOUGH_PLAYERS: felt252 = 'Not enough players to start';
    pub const REG_WINDOW_CLOSED: felt252 = 'Registration window is closed';
    pub const TOURNAMENT_FULL: felt252 = 'Tournament is full';
    pub const LEVEL_TOO_LOW: felt252 = 'Player level too low';
    pub const NOT_REGISTERED: felt252 = 'Player is not registered';
    pub const ALREADY_REGISTERED: felt252 = 'Player already registered';
    pub const PARTICIPANT_LIST_MISMATCH: felt252 = 'Participant list mismatch';
    pub const MATCH_NOT_FOUND: felt252 = 'Match not found';
    pub const MATCH_COMPLETED: felt252 = 'Match already completed';
    pub const INVALID_WINNER: felt252 = 'Winner is not a participant';
    pub const NOT_WINNER: felt252 = 'Caller is not a prize winner';
    pub const PRIZE_CLAIMED: felt252 = 'Prize already claimed';
}
