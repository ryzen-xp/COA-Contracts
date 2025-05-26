use starknet::ContractAddress;

#[dojo::model]
#[derive(Drop, Copy, Serde, Default)]
pub struct Operator {
    #[id]
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
}