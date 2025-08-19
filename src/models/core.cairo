use starknet::ContractAddress;
use crate::helpers::base::ContractAddressDefault;

#[dojo::model]
#[derive(Drop, Copy, Serde, Default)]
pub struct Operator {
    #[key]
    pub id: ContractAddress,
    pub is_operator: bool,
}

#[dojo::model]
#[derive(Drop, Copy, Serde, Default)]
pub struct Contract {
    #[key]
    pub id: felt252,
    pub admin: ContractAddress,
    pub erc1155: ContractAddress,
    pub payment_token: ContractAddress,
    pub escrow_address: ContractAddress,
    pub warehouse: ContractAddress,
    pub registration_fee: u256,
    pub paused: bool,
}


///////////////////EVENTS ////////////////

#[derive(Drop, Serde)]
#[dojo::event]
pub struct GearSpawned {
    #[key]
    pub admin: ContractAddress,
    pub items: Array<u256>,
}

#[derive(Drop, Copy, Serde)]
#[dojo::event]
pub struct ItemPicked {
    #[key]
    pub player_id: ContractAddress,
    #[key]
    pub item_id: u256,
    pub equipped: bool,
    pub via_vehicle: bool,
}
