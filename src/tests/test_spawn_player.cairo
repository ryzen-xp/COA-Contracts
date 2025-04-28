use dojo::test;
use starknet::contract_address::ContractAddress;

use dojo::world::WorldStorage;
use systems::spawn_player::spawn_player;
use components::player::Player;

#[test]
fn test_spawn_player() {
    let world = WorldStorage::default();
    let address = ContractAddress::from(1);

    spawn_player(world, address);

    let player = world.get_component::<Player>(address).unwrap();

    assert(player.level == 1, 'Level must be 1');
    assert(player.hp == 100, 'HP must be 100');
    assert(player.max_hp == 100, 'Max HP must be 100');
    assert(player.coins == 0, 'Coins must be 0');
    assert(player.starks == 0, 'Starks must be 0');
}
