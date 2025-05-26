use crate::models::gear::Gear;

#[starknet::interface]
pub trait IGear<TContractState> {
    fn upgrade(ref self: TContractState, item_id: u256);
    fn equip(ref self: TContractState, item_id: Array<u256>);
    // to equip an object on another object, if necessary
    // blocked for now.
    fn equip_on(ref self: TContractState, item_id: u256, target: u256);
    fn refresh(ref self: TContractState);
    fn get_item_details(ref self: TContractState, item_id: u256) -> Gear;   // Some Item Details struct.
    // use the caller and read the model of both the caller, and the target
    // the target only refers to one target type for now
    // This target type is raidable.
    fn raid(ref self: TContractState, target: u256);
    fn unequip(ref self: TContractState, item_id: Array<u256>);
    fn get_configuration(ref self: TContractState, item_id: u256) -> Option<>;
    // This configure should take in an enum that lists all Gear Types with their structs
    // This function would be blocked at the moment, we shall use the default configuration
    // of the gameplay and how items interact with each other.
    // e.g. guns auto-reload once the time has run out
    // and TODO: Add a delay for auto reload.
    // for a base gun, we default the auto reload to exactly 6 seconds...
    // 
    fn configure(ref self: TContractState, );
    fn auction(ref self: TContractState, item_ids: Array<u256>);
    fn dismantle(ref self: TContractState, item_ids: Array<u256>);
    fn transfer(ref self: TContractState, item_ids: Array<u256>);

    // These functions might be reserved for players within a specific faction

    // this function forges and creates a new item id based
    fn forge(ref self: TContractState, item_ids: Array<u256>);
    fn awaken(ref self: TContractState, exchange: Array<u256>);
    fn can_be_awakened(self: @TContractState, item_ids: Array<u256>) -> Span<bool>;

}

#[dojo::contract]
pub mod GearActions {
    use starknet::{ContractAddress, get_caller_address};
    use dojo::world::WorldStorage;
    use crate::models::gear::{Gear, GearTrait};

    fn dojo_init(ref self: ContractState, admin: ContractAddress) {}

    #[abi(embed_v0)]
    pub impl GearActionsImpl of super::IGear<ContractState> {
        fn upgrade(ref self: ContractState, item_id: u256) {
            // check if the available upgrade materials `id` is present in the caller's address

            // TODO: Security
            // for now, you must check if if the item_id with id is available in the game.
            // This would be done accordingly, so the item struct must have the id of the material
            // or the ids of the list of materials that can upgrade it, and the quantity needed per level
            // and the max level attained.
        }

        fn equip(ref self: ContractState, item_id: Array<u256>) {

        }

        fn equip_on(ref self: TContractState, item_id: u256, target: u256) {

        }
    }

    #[generate_trait]
    pub impl GearInternalImpl of GearInternalTrait {
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"coa")
        }

        fn _assert_admin(self: @ContractState) {
            // assert the admin here.
        }

        fn _retrieve(ref self: ContractState, item_id: u256) {
            // this function should probably return an enum
            // or use an external function in the helper trait that returns an enum
        }
    }
}