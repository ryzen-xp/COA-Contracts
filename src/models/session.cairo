use starknet::ContractAddress;

// Simple session key model - basic version to test compilation
#[dojo::model]
#[derive(Drop, Copy, Serde, Debug, PartialEq)]
pub struct SessionKey {
    #[key]
    pub session_id: felt252, // Unique session identifier
    #[key]
    pub player_address: ContractAddress,
    pub session_key_address: ContractAddress, // The session key contract address
    pub created_at: u64,
    pub expires_at: u64,
    pub last_used: u64,
    pub status: u8, // 0=Active, 1=Expired, 2=Revoked (simple integer instead of enum)
    pub max_transactions: u32,
    pub used_transactions: u32,
    pub is_valid: bool // Simple boolean for session validation
}

// Simple events for session management
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct SessionKeyCreated {
    #[key]
    pub session_id: felt252,
    pub player_address: ContractAddress,
    pub session_key_address: ContractAddress,
    pub expires_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct SessionKeyRevoked {
    #[key]
    pub session_id: felt252,
    pub player_address: ContractAddress,
    pub revoked_by: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct SessionKeyUsed {
    #[key]
    pub session_id: felt252,
    pub player_address: ContractAddress,
    pub action_type: felt252,
    pub success: bool,
}
