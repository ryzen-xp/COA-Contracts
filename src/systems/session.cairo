#[dojo::contract]
pub mod SessionActions {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

    // Constants for session management
    const DEFAULT_SESSION_DURATION: u64 = 21600; // 6 hours in seconds
    const MAX_SESSION_DURATION: u64 = 86400; // 24 hours in seconds
    const MIN_SESSION_DURATION: u64 = 3600; // 1 hour in seconds
    const MAX_TRANSACTIONS_PER_SESSION: u32 = 1000;

    #[external(v0)]
    fn create_session_key(
        ref self: ContractState, session_duration: u64, max_transactions: u32,
    ) -> felt252 {
        let player = get_caller_address();
        let current_time = get_block_timestamp();

        // Validate session duration
        assert(session_duration >= MIN_SESSION_DURATION, 'DURATION_TOO_SHORT');
        assert(session_duration <= MAX_SESSION_DURATION, 'DURATION_TOO_LONG');
        assert(max_transactions > 0, 'INVALID_MAX_TRANSACTIONS');
        assert(max_transactions <= MAX_TRANSACTIONS_PER_SESSION, 'TOO_MANY_TRANSACTIONS');

        // Generate unique session ID
        let session_id = player.into() + current_time.into();

        session_id
    }

    #[external(v0)]
    fn validate_session(
        self: @ContractState, session_id: felt252, player: ContractAddress,
    ) -> bool {
        let current_time = get_block_timestamp();

        // Basic validation - check if session_id is not zero
        // This is a simplified version that will be enhanced later
        session_id != 0
    }

    #[external(v0)]
    fn check_session_expiry(
        self: @ContractState, session_created_at: u64, session_duration: u64,
    ) -> bool {
        let current_time = get_block_timestamp();
        let expiry_time = session_created_at + session_duration;

        // Return true if session has not expired
        current_time < expiry_time
    }

    #[external(v0)]
    fn check_transaction_limit(
        self: @ContractState, used_transactions: u32, max_transactions: u32,
    ) -> bool {
        // Return true if there are transactions left
        used_transactions < max_transactions
    }

    // Middleware functions for game actions
    #[external(v0)]
    fn validate_session_for_action(
        self: @ContractState,
        session_id: felt252,
        player: ContractAddress,
        session_created_at: u64,
        session_duration: u64,
        used_transactions: u32,
        max_transactions: u32,
    ) -> bool {
        // Check if session is valid
        let is_valid = session_id != 0;
        if !is_valid {
            return false;
        }

        // Check if session has expired
        let current_time = get_block_timestamp();
        let expiry_time = session_created_at + session_duration;
        let not_expired = current_time < expiry_time;
        if !not_expired {
            return false;
        }

        // Check if there are transactions left
        let has_transactions = used_transactions < max_transactions;
        if !has_transactions {
            return false;
        }

        true
    }

    #[external(v0)]
    fn require_valid_session(
        self: @ContractState,
        session_id: felt252,
        player: ContractAddress,
        session_created_at: u64,
        session_duration: u64,
        used_transactions: u32,
        max_transactions: u32,
    ) {
        // Check if session is valid
        let is_valid = session_id != 0;
        assert(is_valid, 'INVALID_SESSION');

        // Check if session has expired
        let current_time = get_block_timestamp();
        let expiry_time = session_created_at + session_duration;
        let not_expired = current_time < expiry_time;
        assert(not_expired, 'SESSION_EXPIRED');

        // Check if there are transactions left
        let has_transactions = used_transactions < max_transactions;
        assert(has_transactions, 'NO_TRANSACTIONS_LEFT');
    }

    #[external(v0)]
    fn get_session_status(
        self: @ContractState,
        session_id: felt252,
        player: ContractAddress,
        session_created_at: u64,
        session_duration: u64,
        used_transactions: u32,
        max_transactions: u32,
    ) -> u8 {
        // Return status: 0 = valid, 1 = expired, 2 = no transactions left, 3 = invalid session

        // Check if session is valid
        let is_valid = session_id != 0;
        if !is_valid {
            return 3; // Invalid session
        }

        // Check if session has expired
        let current_time = get_block_timestamp();
        let expiry_time = session_created_at + session_duration;
        let not_expired = current_time < expiry_time;
        if !not_expired {
            return 1; // Expired
        }

        // Check if there are transactions left
        let has_transactions = used_transactions < max_transactions;
        if !has_transactions {
            return 2; // No transactions left
        }

        0 // Valid session
    }

    #[external(v0)]
    fn calculate_remaining_transactions(
        self: @ContractState, used_transactions: u32, max_transactions: u32,
    ) -> u32 {
        if used_transactions >= max_transactions {
            return 0;
        }
        max_transactions - used_transactions
    }

    #[external(v0)]
    fn calculate_session_time_remaining(
        self: @ContractState, session_created_at: u64, session_duration: u64,
    ) -> u64 {
        let current_time = get_block_timestamp();
        let expiry_time = session_created_at + session_duration;

        if current_time >= expiry_time {
            return 0;
        }

        expiry_time - current_time
    }
}
