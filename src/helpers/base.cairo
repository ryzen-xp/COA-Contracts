use starknet::ContractAddress;
use core::num::traits::Zero;

pub impl ContractAddressDefault of Default<ContractAddress> {
    #[inline(always)]
    fn default() -> ContractAddress {
        Zero::zero()
    }
}

fn generate_id(target: felt252, storage: WorldStorage) -> u256 {
    let mut world = self.world_default();
    let mut game_id: Id = world.read_model(target);
    let mut id = game_id.nonce + 1;
    game_id.nonce = id;
    world.write_model(@game_id);
    id
}
