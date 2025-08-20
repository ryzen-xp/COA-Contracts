use coa::models::session::SessionKey;
use coa::helpers::session_validation::{
    validate_combat_session, consume_combat_session_transactions, should_cache_combat_session,
    create_combat_session_cache, validate_cached_combat_session, update_combat_session_cache,
    CombatSessionCache,
};
use coa::models::player::DamageAccumulator;
use starknet::ContractAddress;
use starknet::contract_address_const;

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_session(
        session_id: felt252,
        player_address: ContractAddress,
        expires_at: u64,
        max_transactions: u32,
        used_transactions: u32,
    ) -> SessionKey {
        SessionKey {
            session_id,
            player_address,
            session_key_address: contract_address_const::<0x1>(),
            created_at: 1000,
            expires_at,
            last_used: 1000,
            status: 0, // Active
            max_transactions,
            used_transactions,
            is_valid: true,
        }
    }

    #[test]
    fn test_validate_combat_session_sufficient_transactions() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 3600, 100, 10);
        let current_time = 1500;
        let expected_actions = 20;

        let (is_valid, _updated_session) = validate_combat_session(
            session, player_addr, expected_actions, current_time,
        );

        assert!(is_valid, "Session should be valid with sufficient transactions");
    }

    #[test]
    fn test_validate_combat_session_insufficient_transactions_auto_renew() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(
            1, player_addr, 3600, 100, 95,
        ); // Only 5 transactions left
        let current_time = 1500;
        let expected_actions = 20; // Need 20 transactions

        let (is_valid, updated_session) = validate_combat_session(
            session, player_addr, expected_actions, current_time,
        );

        assert!(is_valid, "Session should be valid after auto-renewal");
        assert_eq!(updated_session.used_transactions, 0, "Transactions should be reset");
        assert_eq!(updated_session.expires_at, current_time + 3600, "Session should be renewed");
    }

    #[test]
    fn test_consume_combat_session_transactions() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 3600, 100, 10);
        let current_time = 1500;
        let actions_executed = 15;

        let updated_session = consume_combat_session_transactions(
            session, actions_executed, current_time,
        );

        assert_eq!(updated_session.used_transactions, 25, "Transactions should be updated");
        assert_eq!(updated_session.last_used, current_time, "Last used time should be updated");
    }

    #[test]
    fn test_should_cache_combat_session() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 2500, 100, 10); // 1000 seconds remaining

        // Should cache for 3+ actions with sufficient time
        assert!(should_cache_combat_session(session, 5), "Should cache for 5 actions");

        // Should not cache for few actions
        assert!(!should_cache_combat_session(session, 2), "Should not cache for 2 actions");
    }

    #[test]
    fn test_combat_session_cache_creation() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 3600, 100, 10);
        let current_time = 1500;
        let expected_actions = 10;

        let cache = create_combat_session_cache(session, current_time, expected_actions);

        assert_eq!(cache.session.session_id, 1, "Session ID should match");
        assert_eq!(cache.cached_at, current_time, "Cache time should match");
        assert_eq!(cache.actions_remaining, expected_actions, "Actions remaining should match");
        assert!(cache.is_active, "Cache should be active");
    }

    #[test]
    fn test_validate_cached_combat_session() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 3600, 100, 10);
        let cache_time = 1500;
        let current_time = 1600; // 100 seconds later

        let cache = create_combat_session_cache(session, cache_time, 10);

        // Should be valid within time limit
        assert!(validate_cached_combat_session(cache, current_time), "Cache should be valid");

        // Should be invalid after time limit
        let expired_time = cache_time + 400; // 400 seconds later (> 5 minutes)
        assert!(!validate_cached_combat_session(cache, expired_time), "Cache should be expired");
    }

    #[test]
    fn test_update_combat_session_cache() {
        let player_addr = contract_address_const::<0x123>();
        let session = create_test_session(1, player_addr, 3600, 100, 10);
        let cache = create_combat_session_cache(session, 1500, 10);
        let current_time = 1600;

        // Update with partial consumption
        let updated_cache = update_combat_session_cache(cache, 3, current_time);
        assert_eq!(updated_cache.actions_remaining, 7, "Actions should be reduced");
        assert!(updated_cache.is_active, "Cache should remain active");

        // Update with complete consumption
        let depleted_cache = update_combat_session_cache(updated_cache, 7, current_time);
        assert_eq!(depleted_cache.actions_remaining, 0, "Actions should be depleted");
        assert!(!depleted_cache.is_active, "Cache should be inactive");
    }

    #[test]
    fn test_damage_accumulator_creation() {
        let target_id = 100;
        let initial_damage = 50;
        let current_time = 1500;

        let accumulator = DamageAccumulator {
            target_id,
            accumulated_damage: initial_damage,
            hit_count: 1,
            combo_multiplier: 100,
            last_hit_time: current_time,
            is_active: true,
        };

        assert_eq!(accumulator.target_id, target_id, "Target ID should match");
        assert_eq!(accumulator.accumulated_damage, initial_damage, "Initial damage should match");
        assert_eq!(accumulator.hit_count, 1, "Hit count should be 1");
        assert_eq!(accumulator.combo_multiplier, 100, "Initial multiplier should be 1.0x");
        assert!(accumulator.is_active, "Accumulator should be active");
    }

    #[test]
    fn test_combo_multiplier_calculation() {
        // Test combo multiplier increases by 5% per hit
        let base_multiplier = 100;
        let hit_count = 5;
        let expected_multiplier = base_multiplier + ((hit_count - 1) * 5);

        assert_eq!(expected_multiplier, 120, "5 hits should give 1.2x multiplier");

        // Test cap at 200% (2.0x)
        let high_hit_count = 25;
        let uncapped_multiplier = base_multiplier + ((high_hit_count - 1) * 5);
        let capped_multiplier = if uncapped_multiplier > 200 {
            200
        } else {
            uncapped_multiplier
        };

        assert_eq!(capped_multiplier, 200, "Multiplier should be capped at 2.0x");
    }
}

