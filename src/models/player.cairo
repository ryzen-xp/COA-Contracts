use dojo::model;
use starknet::ContractAddress;

#[model]
struct Player {
    address: ContractAddress,
    level: u32,
    xp: u64,
    hp: u32,
    max_hp: u32,
    coins: u64,
    starks: u64,
}
