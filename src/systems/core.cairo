/// interface
/// init an admin account, or list of admin accounts, dojo_init
///
/// Spawn tournamemnts and side quests here, if necessary.
#[starknet::interface]
pub trait ICore<TContractState> {
    fn spawn_items(ref self: TContractState, item_types: Array<u256>);
    // move to market only items that have been spawned.
    // if caller is admin, check spawned items and relocate
    // if caller is player,
    fn move_to_market(ref self: TContractState, item_ids: Array<u256>);
    fn add_to_market(ref self: TContractState, item_ids: Array<u256>);
    // can be credits, materials, anything
    fn purchase_item(ref self: TContractState, item_id: u256, quantity: u256);
    fn create_tournament(ref self: TContractState);
    fn join_tournament(ref self: TContractState);
    fn purchase_credits(ref self: TContractState);
}

#[dojo::contract]
pub mod CoreActions {
    use starknet::{ContractAddress, get_caller_address};

    fn dojo_init(ref self: ContractState, admin: ContractAddress, erc1155: ContractAddress) {}

    #[abi(embed_v0)]
    pub impl CoreActionsImpl of super::ICore<ContractState> {
        fn spawn_items(ref self: ContractState, item_types: Array<u256>) {}
        // move to market only items that have been spawned.
        // if caller is admin, check spawned items and relocate
        // if caller is player,
        fn move_to_market(ref self: ContractState, item_ids: Array<u256>) {}
        fn add_to_market(ref self: ContractState, item_ids: Array<u256>) {}
        // can be credits, materials, anything
        fn purchase_item(ref self: ContractState, item_id: u256, quantity: u256) {}
        fn create_tournament(ref self: ContractState) {}
        fn join_tournament(ref self: ContractState) {}
        fn purchase_credits(ref self: ContractState) {}
    }
}
