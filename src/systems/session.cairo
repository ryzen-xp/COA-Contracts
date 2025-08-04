#[dojo::contract]
pub mod SessionActions {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use coa::models::session::{SessionKey, SessionKeyCreated};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use core::poseidon::poseidon_hash_span;

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

        // Generate unique session ID using Poseidon hash to avoid collisions
        let mut hash_data = array![player.into(), current_time.into()];
        let session_id = poseidon_hash_span(hash_data.span());

        // Create session key model
        let session_key = SessionKey {
            session_id,
            player_address: player,
            session_key_address: player, // Using player as session key for now
            created_at: current_time,
            expires_at: current_time + session_duration,
            last_used: current_time,
            status: 0, // Active
            max_transactions,
            used_transactions: 0,
            is_valid: true,
        };

        // Store session in world storage
        let mut world = self.world_default();
        world.write_model(@session_key);

        // Emit creation event
        let event = SessionKeyCreated {
            session_id,
            player_address: player,
            session_key_address: player,
            expires_at: current_time + session_duration,
        };
        world.emit_event(@event);

        session_id
    }

    #[external(v0)]
    fn validate_session(
        self: @ContractState, session_id: felt252, player: ContractAddress,
    ) -> bool {
        // Validate session by reading from storage and checking all properties
        let world = self.world_default();

        // Try to read the session from storage
        let session: SessionKey = world.read_model((session_id, player));

        // Check if session exists (non-zero values indicate it exists)
        if session.session_id == 0 {
            return false;
        }

        // Validate session belongs to the correct player
        if session.player_address != player {
            return false;
        }

        // Check if session is valid
        if !session.is_valid {
            return false;
        }

        // Check session status (0 = Active)
        if session.status != 0 {
            return false;
        }

        // Check if session has expired
        let current_time = get_block_timestamp();
        if current_time >= session.expires_at {
            return false;
        }

        // Check if session has exceeded transaction limit
        if session.used_transactions >= session.max_transactions {
            return false;
        }

        // All validations passed
        true
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
        // Use the comprehensive session validation
        validate_session(self, session_id, player)
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"coa")
        }
    }
}
