use dojo::component;
use starknet::contract_address::ContractAddress;

#[component]
struct Player {
    address: ContractAddress,
    level: u8,
    xp: u64,
    hp: u64,
    max_hp: u64,
    coins: u64,
    starks: u64,
}
