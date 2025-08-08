use starknet::ContractAddress;
use starknet::contract_address_const;
use dojo::test_utils::{spawn_test_world, deploy_contract};

// Import the models and events we're testing
use super::{
    SessionKey, SessionKeyCreated, SessionKeyRevoked, SessionKeyUsed,
    SessionOperationTracked, SessionAutoRenewed, SessionAnalytics, SessionPerformanceMetrics
};

// Test utilities for creating test data
fn create_test_session_key() -> SessionKey {
    SessionKey {
        session_id: 'test_session_123',
        player_address: contract_address_const::<0x123>(),
        session_key_address: contract_address_const::<0x456>(),
        created_at: 1000000,
        expires_at: 2000000,
        last_used: 1500000,
        status: 0, // Active
        max_transactions: 100,
        used_transactions: 25,
        is_valid: true,
    }
}

fn create_expired_session_key() -> SessionKey {
    SessionKey {
        session_id: 'expired_session_456',
        player_address: contract_address_const::<0x789>(),
        session_key_address: contract_address_const::<0xabc>(),
        created_at: 500000,
        expires_at: 800000,
        last_used: 750000,
        status: 1, // Expired
        max_transactions: 50,
        used_transactions: 50,
        is_valid: false,
    }
}

fn create_revoked_session_key() -> SessionKey {
    SessionKey {
        session_id: 'revoked_session_789',
        player_address: contract_address_const::<0xdef>(),
        session_key_address: contract_address_const::<0x111>(),
        created_at: 1200000,
        expires_at: 2200000,
        last_used: 1600000,
        status: 2, // Revoked
        max_transactions: 200,
        used_transactions: 75,
        is_valid: false,
    }
}

#[cfg(test)]
mod session_key_tests {
    use super::*;

    #[test]
    fn test_session_key_creation() {
        let session = create_test_session_key();
        
        assert(session.session_id == 'test_session_123', 'Wrong session ID');
        assert(session.player_address == contract_address_const::<0x123>(), 'Wrong player address');
        assert(session.session_key_address == contract_address_const::<0x456>(), 'Wrong session key address');
        assert(session.created_at == 1000000, 'Wrong created_at');
        assert(session.expires_at == 2000000, 'Wrong expires_at');
        assert(session.last_used == 1500000, 'Wrong last_used');
        assert(session.status == 0, 'Wrong status');
        assert(session.max_transactions == 100, 'Wrong max_transactions');
        assert(session.used_transactions == 25, 'Wrong used_transactions');
        assert(session.is_valid == true, 'Should be valid');
    }

    #[test]
    fn test_session_key_active_status() {
        let session = create_test_session_key();
        assert(session.status == 0, 'Should be active status');
        assert(session.is_valid == true, 'Active session should be valid');
    }

    #[test]
    fn test_session_key_expired_status() {
        let session = create_expired_session_key();
        assert(session.status == 1, 'Should be expired status');
        assert(session.is_valid == false, 'Expired session should be invalid');
    }

    #[test]
    fn test_session_key_revoked_status() {
        let session = create_revoked_session_key();
        assert(session.status == 2, 'Should be revoked status');
        assert(session.is_valid == false, 'Revoked session should be invalid');
    }

    #[test]
    fn test_session_key_transaction_limits() {
        let session = create_test_session_key();
        assert(session.used_transactions <= session.max_transactions, 'Used should not exceed max');
        
        let expired_session = create_expired_session_key();
        assert(expired_session.used_transactions == expired_session.max_transactions, 'Should have reached limit');
    }

    #[test]
    fn test_session_key_time_validity() {
        let session = create_test_session_key();
        assert(session.created_at < session.expires_at, 'Created should be before expiry');
        assert(session.last_used >= session.created_at, 'Last used should be after creation');
        assert(session.last_used <= session.expires_at, 'Last used should be before expiry');
    }

    #[test]
    fn test_session_key_copy_trait() {
        let session1 = create_test_session_key();
        let session2 = session1; // Tests Copy trait
        
        assert(session1.session_id == session2.session_id, 'Copy should preserve session_id');
        assert(session1.player_address == session2.player_address, 'Copy should preserve player_address');
        assert(session1.is_valid == session2.is_valid, 'Copy should preserve is_valid');
    }

    #[test]
    fn test_session_key_equality() {
        let session1 = create_test_session_key();
        let session2 = create_test_session_key();
        
        assert(session1 == session2, 'Identical sessions should be equal');
        
        let mut session3 = create_test_session_key();
        session3.used_transactions = 50;
        assert(session1 != session3, 'Different sessions should not be equal');
    }

    #[test]
    fn test_session_key_edge_cases() {
        // Test with zero values
        let zero_session = SessionKey {
            session_id: 0,
            player_address: contract_address_const::<0x0>(),
            session_key_address: contract_address_const::<0x0>(),
            created_at: 0,
            expires_at: 0,
            last_used: 0,
            status: 0,
            max_transactions: 0,
            used_transactions: 0,
            is_valid: false,
        };
        
        assert(zero_session.session_id == 0, 'Should handle zero session_id');
        assert(zero_session.max_transactions == 0, 'Should handle zero transactions');
        
        // Test with maximum values
        let max_session = SessionKey {
            session_id: 0x7fffffffffffffffffffffffffffffff,
            player_address: contract_address_const::<0xffffffffffffffffffffffffffffffff>(),
            session_key_address: contract_address_const::<0xffffffffffffffffffffffffffffffff>(),
            created_at: 18446744073709551615, // u64::MAX
            expires_at: 18446744073709551615,
            last_used: 18446744073709551615,
            status: 255, // u8::MAX
            max_transactions: 4294967295, // u32::MAX
            used_transactions: 4294967295,
            is_valid: true,
        };
        
        assert(max_session.status == 255, 'Should handle max status');
        assert(max_session.max_transactions == 4294967295, 'Should handle max transactions');
    }
}

#[cfg(test)]
mod session_events_tests {
    use super::*;

    #[test]
    fn test_session_key_created_event() {
        let event = SessionKeyCreated {
            session_id: 'new_session_123',
            player_address: contract_address_const::<0x123>(),
            session_key_address: contract_address_const::<0x456>(),
            expires_at: 2000000,
        };
        
        assert(event.session_id == 'new_session_123', 'Wrong session ID in event');
        assert(event.player_address == contract_address_const::<0x123>(), 'Wrong player address in event');
        assert(event.session_key_address == contract_address_const::<0x456>(), 'Wrong session key address in event');
        assert(event.expires_at == 2000000, 'Wrong expires_at in event');
    }

    #[test]
    fn test_session_key_revoked_event() {
        let event = SessionKeyRevoked {
            session_id: 'revoked_session_456',
            player_address: contract_address_const::<0x789>(),
            revoked_by: contract_address_const::<0xabc>(),
        };
        
        assert(event.session_id == 'revoked_session_456', 'Wrong session ID in revoked event');
        assert(event.player_address == contract_address_const::<0x789>(), 'Wrong player address in revoked event');
        assert(event.revoked_by == contract_address_const::<0xabc>(), 'Wrong revoked_by in event');
    }

    #[test]
    fn test_session_key_used_event() {
        let event = SessionKeyUsed {
            session_id: 'used_session_789',
            player_address: contract_address_const::<0xdef>(),
            action_type: 'EQUIP_GEAR',
            success: true,
        };
        
        assert(event.session_id == 'used_session_789', 'Wrong session ID in used event');
        assert(event.player_address == contract_address_const::<0xdef>(), 'Wrong player address in used event');
        assert(event.action_type == 'EQUIP_GEAR', 'Wrong action_type in event');
        assert(event.success == true, 'Wrong success status in event');
    }

    #[test]
    fn test_session_operation_tracked_event() {
        let event = SessionOperationTracked {
            session_id: 'tracked_session_111',
            player_address: contract_address_const::<0x111>(),
            system_name: 'PLAYER',
            operation_name: 'equip',
            timestamp: 1600000,
            transaction_count: 30,
            remaining_transactions: 70,
        };
        
        assert(event.session_id == 'tracked_session_111', 'Wrong session ID in tracked event');
        assert(event.system_name == 'PLAYER', 'Wrong system_name in event');
        assert(event.operation_name == 'equip', 'Wrong operation_name in event');
        assert(event.timestamp == 1600000, 'Wrong timestamp in event');
        assert(event.transaction_count == 30, 'Wrong transaction_count in event');
        assert(event.remaining_transactions == 70, 'Wrong remaining_transactions in event');
    }

    #[test]
    fn test_session_auto_renewed_event() {
        let event = SessionAutoRenewed {
            session_id: 'renewed_session_222',
            player_address: contract_address_const::<0x222>(),
            old_expires_at: 2000000,
            new_expires_at: 3000000,
            old_transaction_count: 100,
            new_transaction_count: 200,
            renewal_reason: 'TIME_THRESHOLD',
        };
        
        assert(event.session_id == 'renewed_session_222', 'Wrong session ID in renewed event');
        assert(event.old_expires_at == 2000000, 'Wrong old_expires_at in event');
        assert(event.new_expires_at == 3000000, 'Wrong new_expires_at in event');
        assert(event.old_transaction_count == 100, 'Wrong old_transaction_count in event');
        assert(event.new_transaction_count == 200, 'Wrong new_transaction_count in event');
        assert(event.renewal_reason == 'TIME_THRESHOLD', 'Wrong renewal_reason in event');
        assert(event.new_expires_at > event.old_expires_at, 'New expiry should be later');
        assert(event.new_transaction_count > event.old_transaction_count, 'New count should be higher');
    }

    #[test]
    fn test_session_analytics_event() {
        let event = SessionAnalytics {
            session_id: 'analytics_session_333',
            player_address: contract_address_const::<0x333>(),
            total_operations: 150,
            player_operations: 60,
            gear_operations: 50,
            tournament_operations: 40,
            session_duration: 3600,
            average_operation_interval: 24,
            most_used_system: 'PLAYER',
            most_used_operation: 'upgrade',
        };
        
        assert(event.session_id == 'analytics_session_333', 'Wrong session ID in analytics event');
        assert(event.total_operations == 150, 'Wrong total_operations in event');
        assert(event.player_operations == 60, 'Wrong player_operations in event');
        assert(event.gear_operations == 50, 'Wrong gear_operations in event');
        assert(event.tournament_operations == 40, 'Wrong tournament_operations in event');
        
        // Verify operation totals add up correctly
        let sum = event.player_operations + event.gear_operations + event.tournament_operations;
        assert(sum == event.total_operations, 'Operations should sum to total');
        
        assert(event.session_duration == 3600, 'Wrong session_duration in event');
        assert(event.average_operation_interval == 24, 'Wrong average_operation_interval in event');
        assert(event.most_used_system == 'PLAYER', 'Wrong most_used_system in event');
        assert(event.most_used_operation == 'upgrade', 'Wrong most_used_operation in event');
    }

    #[test]
    fn test_session_performance_metrics_event() {
        let event = SessionPerformanceMetrics {
            session_id: 'performance_session_444',
            player_address: contract_address_const::<0x444>(),
            operations_per_minute: 5,
            peak_activity_time: 1650000,
            idle_periods: 3,
            session_efficiency_score: 85,
            auto_renewal_count: 2,
            total_session_value: 1000000000000000000, // 1 ETH in wei as u256
        };
        
        assert(event.session_id == 'performance_session_444', 'Wrong session ID in performance event');
        assert(event.operations_per_minute == 5, 'Wrong operations_per_minute in event');
        assert(event.peak_activity_time == 1650000, 'Wrong peak_activity_time in event');
        assert(event.idle_periods == 3, 'Wrong idle_periods in event');
        assert(event.session_efficiency_score == 85, 'Wrong session_efficiency_score in event');
        assert(event.auto_renewal_count == 2, 'Wrong auto_renewal_count in event');
        assert(event.total_session_value == 1000000000000000000, 'Wrong total_session_value in event');
        
        // Verify efficiency score is in valid range
        assert(event.session_efficiency_score <= 100, 'Efficiency score should be <= 100');
    }

    #[test]
    fn test_event_edge_cases() {
        // Test with zero values
        let zero_analytics = SessionAnalytics {
            session_id: 'zero_analytics',
            player_address: contract_address_const::<0x0>(),
            total_operations: 0,
            player_operations: 0,
            gear_operations: 0,
            tournament_operations: 0,
            session_duration: 0,
            average_operation_interval: 0,
            most_used_system: 0,
            most_used_operation: 0,
        };
        
        assert(zero_analytics.total_operations == 0, 'Should handle zero operations');
        assert(zero_analytics.session_duration == 0, 'Should handle zero duration');
        
        // Test with maximum efficiency score
        let max_performance = SessionPerformanceMetrics {
            session_id: 'max_performance',
            player_address: contract_address_const::<0x555>(),
            operations_per_minute: 4294967295,
            peak_activity_time: 18446744073709551615,
            idle_periods: 4294967295,
            session_efficiency_score: 100,
            auto_renewal_count: 4294967295,
            total_session_value: 340282366920938463463374607431768211455, // u256::MAX
        };
        
        assert(max_performance.session_efficiency_score == 100, 'Should handle max efficiency score');
        assert(max_performance.operations_per_minute == 4294967295, 'Should handle max operations per minute');
    }
}

#[cfg(test)]
mod session_integration_tests {
    use super::*;

    #[test]
    fn test_session_lifecycle() {
        // Test a complete session lifecycle through events
        let session_id = 'lifecycle_session_555';
        let player_addr = contract_address_const::<0x555>();
        let session_key_addr = contract_address_const::<0x666>();
        
        // 1. Session created
        let created_event = SessionKeyCreated {
            session_id,
            player_address: player_addr,
            session_key_address: session_key_addr,
            expires_at: 2000000,
        };
        
        // 2. Session used multiple times
        let used_event = SessionKeyUsed {
            session_id,
            player_address: player_addr,
            action_type: 'EQUIP_GEAR',
            success: true,
        };
        
        // 3. Session tracked
        let tracked_event = SessionOperationTracked {
            session_id,
            player_address: player_addr,
            system_name: 'GEAR',
            operation_name: 'equip',
            timestamp: 1500000,
            transaction_count: 10,
            remaining_transactions: 90,
        };
        
        // 4. Session auto-renewed
        let renewed_event = SessionAutoRenewed {
            session_id,
            player_address: player_addr,
            old_expires_at: 2000000,
            new_expires_at: 3000000,
            old_transaction_count: 100,
            new_transaction_count: 200,
            renewal_reason: 'TRANSACTION_LIMIT',
        };
        
        // 5. Final analytics
        let analytics_event = SessionAnalytics {
            session_id,
            player_address: player_addr,
            total_operations: 50,
            player_operations: 20,
            gear_operations: 20,
            tournament_operations: 10,
            session_duration: 1500000,
            average_operation_interval: 30000,
            most_used_system: 'GEAR',
            most_used_operation: 'equip',
        };
        
        // Verify consistency across events
        assert(created_event.session_id == used_event.session_id, 'Session IDs should match');
        assert(created_event.player_address == tracked_event.player_address, 'Player addresses should match');
        assert(renewed_event.new_expires_at > created_event.expires_at, 'Renewal should extend expiry');
        assert(analytics_event.most_used_system == tracked_event.system_name, 'Most used should match tracking');
    }

    #[test]
    fn test_session_validation_logic() {
        let mut session = create_test_session_key();
        
        // Test valid session
        assert(session.is_valid == true, 'Should be valid initially');
        assert(session.status == 0, 'Should be active');
        
        // Test expired session logic
        session.status = 1; // Expired
        session.is_valid = false;
        assert(session.is_valid == false, 'Expired session should be invalid');
        
        // Test revoked session logic  
        session.status = 2; // Revoked
        session.is_valid = false;
        assert(session.is_valid == false, 'Revoked session should be invalid');
        
        // Test transaction limit exceeded
        session.used_transactions = session.max_transactions;
        assert(session.used_transactions == session.max_transactions, 'Should have reached transaction limit');
    }

    #[test]
    fn test_performance_metrics_calculation() {
        let session_duration: u64 = 3600; // 1 hour
        let total_operations: u32 = 60;
        let operations_per_minute = total_operations * 60 / (session_duration as u32);
        
        let metrics = SessionPerformanceMetrics {
            session_id: 'calc_test_session',
            player_address: contract_address_const::<0x777>(),
            operations_per_minute,
            peak_activity_time: 1800000,
            idle_periods: 5,
            session_efficiency_score: 90,
            auto_renewal_count: 1,
            total_session_value: 500000000000000000, // 0.5 ETH
        };
        
        assert(metrics.operations_per_minute == 1, 'Should calculate 1 operation per minute');
        assert(metrics.session_efficiency_score == 90, 'Should have high efficiency');
        assert(metrics.idle_periods == 5, 'Should track idle periods');
    }
}