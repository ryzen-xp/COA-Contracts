use crate::models::player::Player;

#[starknet::interface]
pub trait IPlayer<TContractState> {
    fn new(ref self: TContractState, faction: felt252);
    fn deal_damage(ref self: TContractState, target: Array<u256>, target_types: Array<felt252>, with_item: u256);
    fn get_player(self: @TContractState, player_id: u256) -> Player;
    fn mint(ref self: TContractState, );
    fn register_guild(ref self: TContractState);
}

#[dojo::contract]
pub mod PlayerActions {
    use starknet::{ContractAddress, get_caller_address};
    use crate::models::player::{Player, PlayerTrait};
    use super::IPlayer;


    fn dojo_init(ref self: ContractState, admin: ContractAddress, default_amount_of_credits: u256) {
        // write admin
        // write default amount of credits.
        
    }

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayer<ContractState> {
        fn new(ref self: ContractState, faction: felt252) {
            // create the player
            // and call mint
            // maybe in the future, you implement a `mint_default()`
        }

        fn deal_damage(ref self: ContractState, target: Array<u256>, target_types: Array<felt252>, with_items: Array<u256>) {
            // check if the player and the items exists..
            // assert that the items are something that can deal damage
            // from no. 2, not just assert, handle appropriately, but do not panic
            // factor in the faction type and add additional damage
            // factor in the weapon type and xp // rank trait.
            // and factor in the item type, if the item has been upgraded
            // check if the item has been equipped
            // to find out the item's output when upgraded, call the item.output(val), where val is the upgraded level.

            // factor in the target's damage factor... might later turn out not to be damaged
            // this means that each target or item should have a damage factor, and might cause credits to be repaired 


            // for the target, the above is if the target_type is an object.
            // if the target type is a living organism, check all the eqippable traits
            // this means that the PlayerTrait should have a deduct
        }


    }
}