#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct PetStats {
    #[key]
    pub asset_id: u256,
    pub loyalty: u64,
    pub intelligence: u64,
    pub agility: u64,
    pub special_ability: felt252,
    pub energy: u64,
}
