#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct ArmorStats {
    #[key]
    pub asset_id: u256,
    pub defense: u64,
    pub durability: u64,
    pub weight: u64,
    pub slot_type: felt252,
}

#[generate_trait]
pub impl ArmorStatsImpl of ArmorStatsTrait {
    fn new(
        asset_id: u256, defense: u64, durability: u64, weight: u64, slot_type: felt252,
    ) -> ArmorStats {
        ArmorStats { asset_id, defense, durability, weight, slot_type }
    }
}
