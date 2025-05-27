use starknet::ContractAddress;
use core::num::traits::Zero;
use dojo::storage::WorldStorage;

pub impl ContractAddressDefault of Default<ContractAddress> {
    #[inline(always)]
    fn default() -> ContractAddress {
        Zero::zero()
    }
}

fn generate_id(target: felt252, world: WorldStorage) -> u256 {
    let mut game_id: Id = world.read_model(target);
    let mut id = game_id.nonce + 1;
    game_id.nonce = id;
    world.write_model(@game_id);
    id
}
