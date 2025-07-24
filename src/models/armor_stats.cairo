#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct Armor {
    #[key]
    pub asset_id: u256,
    pub defense: u64,
    pub durability: u64,
    pub weight: u64,
    pub slot_type: felt252,
}
