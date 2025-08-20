use starknet::ContractAddress;
use starknet::get_block_timestamp;
use super::*;
use crate::models::session::SessionKey;

// Constants for session management
pub const MIN_SESSION_DURATION: u64 = 3600; // 1 hour in seconds
pub const MAX_SESSION_DURATION: u64 = 86400; // 24 hours in seconds
pub const MAX_TRANSACTIONS_PER_SESSION: u32 = 1000;
pub const AUTO_RENEWAL_THRESHOLD: u64 = 300; // 5 minutes in seconds
pub const DEFAULT_RENEWAL_DURATION: u64 = 3600; // 1 hour in seconds

// Constants for session limits per player
pub const MAX_ACTIVE_SESSIONS_PER_PLAYER: u32 = 5; // Maximum active sessions per player
pub const SESSION_CLEANUP_THRESHOLD: u64 =
    86400; // 24 hours - sessions older than this are considered inactive

// Error constants for session validation
pub const ERROR_INVALID_SESSION: felt252 = 'INVALID_SESSION';
pub const ERROR_SESSION_EXPIRED: felt252 = 'SESSION_EXPIRED';
pub const ERROR_NO_TRANSACTIONS_LEFT: felt252 = 'NO_TRANSACTIONS_LEFT';
pub const ERROR_UNAUTHORIZED_PLAYER: felt252 = 'UNAUTHORIZED_PLAYER';
pub const ERROR_SESSION_NOT_ACTIVE: felt252 = 'SESSION_NOT_ACTIVE';

// Helper function to calculate time remaining for a session
pub fn calculate_session_time_remaining(session: SessionKey) -> u64 {
    let current_time = get_block_timestamp();
    if current_time >= session.expires_at {
        0
    } else {
        session.expires_at - current_time
    }
}

// Helper function to calculate time remaining for a session with custom time (for testing)
pub fn calculate_session_time_remaining_with_time(session: SessionKey, current_time: u64) -> u64 {
    if current_time >= session.expires_at {
        0
    } else {
        session.expires_at - current_time
    }
}

// Helper function to check if session is expired
pub fn is_session_expired(session: SessionKey) -> bool {
    let current_time = get_block_timestamp();
    current_time >= session.expires_at
}

// Helper function to check if session is expired with custom time (for testing)
pub fn is_session_expired_with_time(session: SessionKey, current_time: u64) -> bool {
    current_time >= session.expires_at
}

// Helper function to check if session needs renewal
pub fn needs_auto_renewal(session: SessionKey) -> bool {
    let time_remaining = calculate_session_time_remaining(session);
    time_remaining < AUTO_RENEWAL_THRESHOLD && time_remaining > 0
}

// Helper function to check if session needs renewal with custom time (for testing)
pub fn needs_auto_renewal_with_time(session: SessionKey, current_time: u64) -> bool {
    let time_remaining = calculate_session_time_remaining_with_time(session, current_time);
    time_remaining < AUTO_RENEWAL_THRESHOLD && time_remaining > 0
}

// Helper function to check if session has transactions left
pub fn has_transactions_left(session: SessionKey) -> bool {
    session.used_transactions < session.max_transactions
}

// Helper function to validate session basic parameters
pub fn validate_session_parameters(session: SessionKey, caller: ContractAddress) -> bool {
    // Check if session exists
    if session.session_id == 0 {
        return false;
    }

    // Check if session belongs to caller
    if session.player_address != caller {
        return false;
    }

    // Check if session is valid
    if !session.is_valid {
        return false;
    }

    // Check if session is active
    if session.status != 0 {
        return false;
    }

    // Check if session is not expired
    if is_session_expired(session) {
        return false;
    }

    // Check if session has transactions left
    if !has_transactions_left(session) {
        return false;
    }

    true
}

// Helper function to validate session basic parameters with custom time (for testing)
pub fn validate_session_parameters_with_time(
    session: SessionKey, caller: ContractAddress, current_time: u64,
) -> bool {
    // Check if session exists
    if session.session_id == 0 {
        return false;
    }

    // Check if session belongs to caller
    if session.player_address != caller {
        return false;
    }

    // Check if session is valid
    if !session.is_valid {
        return false;
    }

    // Check if session is active
    if session.status != 0 {
        return false;
    }

    // Check if session is not expired
    if is_session_expired_with_time(session, current_time) {
        return false;
    }

    // Check if session has transactions left
    if !has_transactions_left(session) {
        return false;
    }

    true
}

// Helper function to get session status as a number
pub fn get_session_status(session: SessionKey) -> u8 {
    if session.session_id == 0 {
        return 3; // Invalid session
    }
    if !session.is_valid {
        return 2; // Revoked session
    }
    if session.status != 0 {
        return 1; // Inactive session
    }
    if is_session_expired(session) {
        return 4; // Expired session
    }
    if !has_transactions_left(session) {
        return 5; // No transactions left
    }
    0 // Valid session
}

// Helper function to get session status as a number with custom time (for testing)
pub fn get_session_status_with_time(session: SessionKey, current_time: u64) -> u8 {
    if session.session_id == 0 {
        return 3; // Invalid session
    }
    if !session.is_valid {
        return 2; // Revoked session
    }
    if session.status != 0 {
        return 1; // Inactive session
    }
    if is_session_expired_with_time(session, current_time) {
        return 4; // Expired session
    }
    if !has_transactions_left(session) {
        return 5; // No transactions left
    }
    0 // Valid session
}

// Function to check if a player can create more sessions
// This should be called before creating a new session
pub fn can_player_create_session(player_sessions: Array<SessionKey>, current_time: u64) -> bool {
    let mut active_count = 0;
    let mut i = 0;
    let len = player_sessions.len();

    while i < len {
        let session = player_sessions.at(i);

        // Count only valid, active, non-expired sessions
        if (*session).is_valid
            && (*session).status == 0
            && current_time < (*session).expires_at
            && (*session).used_transactions < (*session).max_transactions {
            active_count += 1;
        }

        i += 1;
    };

    return active_count < MAX_ACTIVE_SESSIONS_PER_PLAYER;
}

// Centralized session validation function that all systems should use
// This ensures consistency across all systems and includes auto-renewal
pub fn validate_session_for_action_centralized(
    session: SessionKey, caller: ContractAddress, current_time: u64,
) -> (bool, SessionKey) {
    // First, validate the session using our helper
    if !validate_session_parameters_with_time(session, caller, current_time) {
        return (false, session);
    }

    // Check if session needs auto-renewal (less than 5 minutes remaining)
    let time_remaining = calculate_session_time_remaining_with_time(session, current_time);

    if time_remaining < AUTO_RENEWAL_THRESHOLD && time_remaining > 0 {
        // Auto-renew the session
        let mut renewed_session = session;
        renewed_session.expires_at = current_time + DEFAULT_RENEWAL_DURATION;
        renewed_session.last_used = current_time;
        renewed_session.max_transactions = 100; // Reset to default
        renewed_session.used_transactions = 0; // Reset transaction count

        return (true, renewed_session);
    }

    // Session is valid and doesn't need renewal
    (true, session)
}

// Combat session validation for batch operations
// Validates session once for entire combat sequence
pub fn validate_combat_session(
    session: SessionKey, caller: ContractAddress, expected_actions: u32, current_time: u64,
) -> (bool, SessionKey) {
    // First, validate the session using our helper
    if !validate_session_parameters_with_time(session, caller, current_time) {
        return (false, session);
    }

    // Check if session has enough transactions for the entire combat sequence
    let transactions_needed = expected_actions;
    let available_transactions = session.max_transactions - session.used_transactions;

    if available_transactions < transactions_needed {
        // Auto-renew if needed to accommodate the batch
        let mut renewed_session = session;
        renewed_session.expires_at = current_time + DEFAULT_RENEWAL_DURATION;
        renewed_session.last_used = current_time;
        renewed_session.max_transactions = MAX_TRANSACTIONS_PER_SESSION; // Use max for combat
        renewed_session.used_transactions = 0; // Reset transaction count

        return (true, renewed_session);
    }

    // Session is valid and has enough transactions
    (true, session)
}

// Batch session usage tracking - accumulates transaction count for batch operations
pub fn consume_combat_session_transactions(
    mut session: SessionKey, actions_executed: u32, current_time: u64,
) -> SessionKey {
    // Update transaction count for all actions in the batch
    session.used_transactions += actions_executed;
    session.last_used = current_time;

    session
}

// Check if session should be cached for combat operations
pub fn should_cache_combat_session(session: SessionKey, expected_actions: u32) -> bool {
    // Cache if we're doing a significant number of actions (3+ actions)
    // and session has sufficient time remaining (more than 10 minutes)
    let time_remaining = calculate_session_time_remaining(session);
    expected_actions >= 3 && time_remaining > 600 // 10 minutes
}

// Combat session cache structure to reduce storage reads
#[derive(Drop, Copy, Serde)]
pub struct CombatSessionCache {
    pub session: SessionKey,
    pub cached_at: u64,
    pub actions_remaining: u32,
    pub is_active: bool,
}

// Create a new combat session cache
pub fn create_combat_session_cache(
    session: SessionKey, current_time: u64, expected_actions: u32,
) -> CombatSessionCache {
    CombatSessionCache {
        session, cached_at: current_time, actions_remaining: expected_actions, is_active: true,
    }
}

// Validate cached combat session without storage read
pub fn validate_cached_combat_session(cache: CombatSessionCache, current_time: u64) -> bool {
    // Check if cache is still valid (within 5 minutes of caching)
    let cache_age = current_time - cache.cached_at;
    if cache_age > 300 { // 5 minutes
        return false;
    }

    // Check if session hasn't expired
    if current_time >= cache.session.expires_at {
        return false;
    }

    // Check if we still have actions remaining
    cache.actions_remaining > 0 && cache.is_active
}

// Update combat session cache after action execution
pub fn update_combat_session_cache(
    mut cache: CombatSessionCache, actions_consumed: u32, current_time: u64,
) -> CombatSessionCache {
    if actions_consumed >= cache.actions_remaining {
        cache.actions_remaining = 0;
        cache.is_active = false;
    } else {
        cache.actions_remaining -= actions_consumed;
    }

    cache
}

// Invalidate combat session cache
pub fn invalidate_combat_session_cache(mut cache: CombatSessionCache) -> CombatSessionCache {
    cache.is_active = false;
    cache.actions_remaining = 0;
    cache
}
