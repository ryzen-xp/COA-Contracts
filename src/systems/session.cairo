#[dojo::contract]
pub mod SessionActions {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::poseidon::poseidon_hash_span;
    use starknet::storage::Map;
    use starknet::storage::map::MapTrait;

    // --------------------------------------------
    // Storage
    // --------------------------------------------
    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub struct SessionInfo {
        session_key_address: ContractAddress,
        created_at: u64,
        expires_at: u64,
        last_used: u64,
        status: u8,              // 0=Active, 1=Expired, 2=Revoked
        max_transactions: u32,
        used_transactions: u32,
        is_valid: bool,
        session_type: u8,        // 0=Basic, 1=Premium, 2=VIP
    }

    #[storage]
    pub struct Storage {
        // sessions[hash(player, session_id)] => SessionInfo
        sessions: Map<felt252, SessionInfo>,
    }

    // --------------------------------------------
    // Events
    // --------------------------------------------
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        SessionCreated: SessionCreated,
        SessionRevoked: SessionRevoked,
        OperationTracked: OperationTracked,
        SessionAutoRenewed: SessionAutoRenewed,
    }

    #[derive(Drop, Serde, starknet::Event)]
    pub struct SessionCreated {
        session_id: felt252,
        player_address: ContractAddress,
        session_key_address: ContractAddress,
        expires_at: u64,
        session_type: u8,
    }

    #[derive(Drop, Serde, starknet::Event)]
    pub struct SessionRevoked {
        session_id: felt252,
        player_address: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Event)]
    pub struct OperationTracked {
        session_id: felt252,
        player_address: ContractAddress,
        system_name: felt252,
        operation_name: felt252,
        timestamp: u64,
        transaction_count: u32,
        remaining_transactions: u32,
    }

    #[derive(Drop, Serde, starknet::Event)]
    pub struct SessionAutoRenewed {
        session_id: felt252,
        player_address: ContractAddress,
        old_expires_at: u64,
        new_expires_at: u64,
        old_transaction_count: u32,
        new_transaction_count: u32,
        renewal_reason: felt252,
    }

    // --------------------------------------------
    // Constants
    // --------------------------------------------
    const DEFAULT_SESSION_DURATION: u64 = 21600; // 6h
    const MAX_SESSION_DURATION: u64 = 86400; // 24h
    const MIN_SESSION_DURATION: u64 = 3600; // 1h
    const MAX_TRANSACTIONS_PER_SESSION: u32 = 1000;

    const DEFAULT_AUTO_RENEWAL_THRESHOLD: u64 = 300; // 5 min
    const DEFAULT_AUTO_RENEWAL_DURATION: u64 = 3600; // 1h
    const DEFAULT_AUTO_RENEWAL_TRANSACTIONS: u32 = 100;

    const SYSTEM_PLAYER: felt252 = 'PLAYER';
    const SYSTEM_GEAR: felt252 = 'GEAR';
    const SYSTEM_TOURNAMENT: felt252 = 'TOURNAMENT';

    const RENEWAL_TIME_THRESHOLD: felt252 = 'TIME_THRESHOLD';

    const SESSION_TYPE_BASIC: u8 = 0;
    const SESSION_TYPE_PREMIUM: u8 = 1;
    const SESSION_TYPE_VIP: u8 = 2;

    // --------------------------------------------
    // Helpers (internal)
    // --------------------------------------------
    fn make_key(player: ContractAddress, session_id: felt252) -> felt252 {
        let mut data = array![player.into(), session_id];
        poseidon_hash_span(data.span())
    }

    fn read_session(self: @ContractState, player: ContractAddress, session_id: felt252) -> (bool, SessionInfo) {
        let key = make_key(player, session_id);
        let info = self.sessions.read(key);
        let exists = info.created_at != 0;
        (exists, info)
    }

    fn write_session(ref self: ContractState, player: ContractAddress, session_id: felt252, info: SessionInfo) {
        let key = make_key(player, session_id);
        self.sessions.write(key, info);
    }

    // --------------------------------------------
    // API
    // --------------------------------------------
    #[external(v0)]
    fn create_session_key(ref self: ContractState, session_duration: u64, max_transactions: u32) -> felt252 {
        let player = get_caller_address();
        let current_time = get_block_timestamp();

        assert(session_duration >= MIN_SESSION_DURATION, 'DURATION_TOO_SHORT');
        assert(session_duration <= MAX_SESSION_DURATION, 'DURATION_TOO_LONG');
        assert(max_transactions > 0, 'INVALID_MAX_TRANSACTIONS');
        assert(max_transactions <= MAX_TRANSACTIONS_PER_SESSION, 'TOO_MANY_TRANSACTIONS');

        let mut data = array![player.into(), current_time.into()];
        let session_id = poseidon_hash_span(data.span());

        let info = SessionInfo {
            session_key_address: player,
            created_at: current_time,
            expires_at: current_time + session_duration,
            last_used: current_time,
            status: 0,
            max_transactions,
            used_transactions: 0,
            is_valid: true,
            session_type: SESSION_TYPE_BASIC,
        };
        write_session(ref self, player, session_id, info);

        self.emit(Event::SessionCreated(SessionCreated {
            session_id,
            player_address: player,
            session_key_address: player,
            expires_at: info.expires_at,
            session_type: SESSION_TYPE_BASIC,
        }));

        session_id
    }

    #[external(v0)]
    fn create_session_key_with_config(
        ref self: ContractState,
        session_duration: u64,
        max_transactions: u32,
        _auto_renewal_threshold: u64,
        _auto_renewal_duration: u64,
        _auto_renewal_transactions: u32,
    ) -> felt252 {
        create_session_key(ref self, session_duration, max_transactions)
    }

    #[external(v0)]
    fn create_premium_session(ref self: ContractState, session_duration: u64, max_transactions: u32, session_type: u8) -> felt252 {
        let player = get_caller_address();
        let current_time = get_block_timestamp();
        assert(session_type == SESSION_TYPE_PREMIUM || session_type == SESSION_TYPE_VIP, 'INVALID_SESSION_TYPE');

        let adjusted_duration = if session_type == SESSION_TYPE_VIP { session_duration * 2 } else { session_duration };
        let adjusted_transactions = if session_type == SESSION_TYPE_VIP { max_transactions * 3 } else { max_transactions * 2 };

        assert(adjusted_duration >= MIN_SESSION_DURATION, 'DURATION_TOO_SHORT');
        assert(adjusted_duration <= MAX_SESSION_DURATION * 2, 'DURATION_TOO_LONG');
        assert(adjusted_transactions > 0, 'INVALID_MAX_TRANSACTIONS');

        let mut data = array![player.into(), current_time.into(), session_type.into()];
        let session_id = poseidon_hash_span(data.span());

        let info = SessionInfo {
            session_key_address: player,
            created_at: current_time,
            expires_at: current_time + adjusted_duration,
            last_used: current_time,
            status: 0,
            max_transactions: adjusted_transactions,
            used_transactions: 0,
            is_valid: true,
            session_type,
        };
        write_session(ref self, player, session_id, info);

        self.emit(Event::SessionCreated(SessionCreated {
            session_id,
            player_address: player,
            session_key_address: player,
            expires_at: info.expires_at,
            session_type,
        }));

        session_id
    }

    #[external(v0)]
    fn track_session_operation(ref self: ContractState, session_id: felt252, system_name: felt252, operation_name: felt252) {
        let player = get_caller_address();
        let now = get_block_timestamp();

        let (exists, mut info) = read_session(@self, player, session_id);
        assert(exists, 'SESSION_NOT_FOUND');
        assert(info.is_valid && info.status == 0, 'SESSION_INVALID');

        // update usage
        info.used_transactions += 1;
        info.last_used = now;
        write_session(ref self, player, session_id, info);

        let remaining = if info.used_transactions >= info.max_transactions { 0 } else { info.max_transactions - info.used_transactions };
        self.emit(Event::OperationTracked(OperationTracked {
            session_id,
            player_address: player,
            system_name,
            operation_name,
            timestamp: now,
            transaction_count: info.used_transactions,
            remaining_transactions: remaining,
        }));
    }

    #[external(v0)]
    fn get_player_sessions(self: @ContractState, _player: ContractAddress) -> Array<felt252> {
        // Pendiente: indexación por jugador. Por ahora vacío para compatibilidad.
        array![]
    }

    #[external(v0)]
    fn revoke_session(ref self: ContractState, session_id: felt252) {
        let player = get_caller_address();
        let (exists, mut info) = read_session(@self, player, session_id);
        assert(exists, 'SESSION_NOT_FOUND');
        info.is_valid = false;
        info.status = 2; // Revoked
        write_session(ref self, player, session_id, info);
        self.emit(Event::SessionRevoked(SessionRevoked { session_id, player_address: player }));
    }

    #[external(v0)]
    fn validate_session(self: @ContractState, session_id: felt252, player: ContractAddress) -> bool {
        if session_id == 0 { return false; }
        let caller = get_caller_address();
        if caller != player { return false; }
        let (exists, info) = read_session(self, player, session_id);
        if !exists { return false; }
        if !info.is_valid || info.status != 0 { return false; }
        let now = get_block_timestamp();
        if now >= info.expires_at { return false; }
        if info.used_transactions >= info.max_transactions { return false; }
        true
    }

    #[external(v0)]
    fn validate_session_for_action(ref self: ContractState, session_id: felt252, player: ContractAddress) -> bool {
        if session_id == 0 { return false; }
        let caller = get_caller_address();
        if caller != player { return false; }

        let (exists, mut info) = read_session(@self, player, session_id);
        if !exists { return false; }
        if !info.is_valid || info.status != 0 { return false; }

        let now = get_block_timestamp();
        if now >= info.expires_at { return false; }
        if info.used_transactions >= info.max_transactions { return false; }

        // Auto-renew if near expiration
        let time_remaining = if now >= info.expires_at { 0 } else { info.expires_at - now };
        if time_remaining < DEFAULT_AUTO_RENEWAL_THRESHOLD {
            let old_exp = info.expires_at;
            let old_tx = info.used_transactions;
            info.expires_at = now + DEFAULT_AUTO_RENEWAL_DURATION;
            info.used_transactions = 0;
            info.max_transactions = DEFAULT_AUTO_RENEWAL_TRANSACTIONS;
            write_session(ref self, player, session_id, info);
            self.emit(Event::SessionAutoRenewed(SessionAutoRenewed {
                session_id,
                player_address: player,
                old_expires_at: old_exp,
                new_expires_at: info.expires_at,
                old_transaction_count: old_tx,
                new_transaction_count: info.used_transactions,
                renewal_reason: RENEWAL_TIME_THRESHOLD,
            }));
        }

        // Mark usage for this action
        info.last_used = now;
        info.used_transactions += 1;
        write_session(ref self, player, session_id, info);

        true
    }

    #[external(v0)]
    fn get_session_status(self: @ContractState, session_id: felt252, player: ContractAddress) -> u8 {
        if session_id == 0 { return 3; }
        let caller = get_caller_address();
        if caller != player { return 3; }
        let (exists, info) = read_session(self, player, session_id);
        if !exists { return 3; }
        if !info.is_valid || info.status != 0 { return 3; }
        let now = get_block_timestamp();
        if now >= info.expires_at { return 1; }
        if info.used_transactions >= info.max_transactions { return 2; }
        0
    }

    // Helpers existentes para compatibilidad de tests
    #[external(v0)]
    fn calculate_remaining_transactions(self: @ContractState, used_transactions: u32, max_transactions: u32) -> u32 {
        if used_transactions >= max_transactions { 0 } else { max_transactions - used_transactions }
    }

    #[external(v0)]
    fn calculate_session_time_remaining(self: @ContractState, session_created_at: u64, session_duration: u64) -> u64 {
        let now = get_block_timestamp();
        let end = session_created_at + session_duration;
        if now >= end { 0 } else { end - now }
    }

    #[external(v0)]
    fn check_session_expiry(self: @ContractState, session_created_at: u64, session_duration: u64) -> bool {
        let now = get_block_timestamp();
        let expiry = session_created_at + session_duration;
        now < expiry
    }

    #[external(v0)]
    fn check_transaction_limit(self: @ContractState, used_transactions: u32, max_transactions: u32) -> bool {
        used_transactions < max_transactions
    }

    // Stubs para analytics (mantener compatibilidad de firmas actuales)
    #[external(v0)]
    fn get_session_analytics(self: @ContractState, session_id: felt252) -> (felt252, ContractAddress, u32, u64, u64, felt252) {
        let player = get_caller_address();
        (session_id, player, 0, 0, 0, SYSTEM_PLAYER)
    }

    #[external(v0)]
    fn get_session_performance_metrics(self: @ContractState, session_id: felt252) -> (felt252, ContractAddress, u32, u64, u32, u32, u256) {
        let player = get_caller_address();
        (session_id, player, 0, 0, 0, 0, 0_u256)
    }

    #[external(v0)]
    fn get_session_analytics_basic(
        self: @ContractState,
        _session_id: felt252,
        session_created_at: u64,
        session_duration: u64,
        used_transactions: u32,
        max_transactions: u32,
    ) -> (u64, u64, u32) {
        let now = get_block_timestamp();
        let actual = if now > session_created_at + session_duration { session_duration } else { now - session_created_at };
        let avg_interval = if used_transactions > 0 { actual / used_transactions.into() } else { 0 };
        let efficiency = if max_transactions > 0 { (used_transactions * 100) / max_transactions } else { 0 };
        (actual, avg_interval, efficiency)
    }

    #[external(v0)]
    fn calculate_session_performance(
        self: @ContractState,
        session_created_at: u64,
        session_duration: u64,
        used_transactions: u32,
        max_transactions: u32,
    ) -> (u32, u32, u32) {
        let now = get_block_timestamp();
        let actual = if now > session_created_at + session_duration { session_duration } else { now - session_created_at };
        let opm = if actual > 0 { (used_transactions * 60) / actual.try_into().unwrap() } else { 0 };
        let efficiency = if max_transactions > 0 { (used_transactions * 100) / max_transactions } else { 0 };
        let remaining = if used_transactions >= max_transactions { 0 } else { max_transactions - used_transactions };
        (opm, efficiency, remaining)
    }
}
