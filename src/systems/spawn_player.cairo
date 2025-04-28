use dojo::system;
use dojo::world::WorldStorage;
use starknet::contract_address::ContractAddress;

use components::player::Player;

#[system]
fn spawn_player(world: WorldStorage, address: ContractAddress) {
    world.set_component(
        address,
        Player {
            address,
            level: 1,
            xp: 0,
            hp: 100,
            max_hp: 100,
            coins: 0,
            starks: 0,
        }
    );
}
