use dojo::system;
use starknet::ContractAddress;
use crate::models::player::Player;

#[system]
mod spawn_player {
    use super::*;

    pub fn spawn_player(address: ContractAddress) {
        Player::set(
            address,
            Player { address: address, level: 1, xp: 0, hp: 100, max_hp: 100, coins: 0, starks: 0 },
        );
    }
}
