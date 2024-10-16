use starknet::ContractAddress;

#[starknet::interface]
trait IMercenaryActions<TContractState> {
    fn mint(self:@TContractState,owner:ContractAddress) ->u128;
}



#[dojo::contract]
mod mercenary_actions {
use super::IMercenaryActions;
use starknet::ContractAddress;

use dojo_starter::{components::{mercenary::MercenaryTrait},systems::{mercenary::MercenaryWorldTrait}};


#[abi(embed_v0)]
impl MercenaryActionsImpl of IMercenaryActions<ContractState> {
    fn mint(self:@ContractState, owner:ContractAddress)->u128 {
        let world = self.world_dispatcher.read();
        world.mint_mercenary(owner).id
    }
}
}
