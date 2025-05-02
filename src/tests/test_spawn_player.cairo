use dojo::test;
use starknet::ContractAddress;
use crate::models::player::Player;
use crate::systems::spawn_player::spawn_player;

#[test]
fn test_spawn_player() {
    let player_address = ContractAddress::from(1234);

    // Spawn the player
    spawn_player(player_address);

    // Fetch the player from storage
    let player = Player::get(player_address).unwrap();

    assert(player.address == player_address, 'Address mismatch');
    assert(player.level == 1, 'Level mismatch');
    assert(player.xp == 0, 'XP mismatch');
    assert(player.hp == 100, 'HP mismatch');
    assert(player.max_hp == 100, 'Max HP mismatch');
    assert(player.coins == 0, 'Coins mismatch');
    assert(player.starks == 0, 'Starks mismatch');
}
