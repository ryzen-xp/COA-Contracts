// Specific gear structs for different categories
#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct WeaponStats {
    #[key]
    pub asset_id: u256,
    pub damage: u64,
    pub range: u64,
    pub accuracy: u64,
    pub fire_rate: u64,
    pub ammo_capacity: u64,
    pub reload_time: u64,
}

#[generate_trait]
pub impl WeaponStatsImpl of WeaponStatsTrait {
    fn new(
        asset_id: u256,
        damage: u64,
        range: u64,
        accuracy: u64,
        fire_rate: u64,
        ammo_capacity: u64,
        reload_time: u64,
    ) -> WeaponStats {
        WeaponStats { asset_id, damage, range, accuracy, fire_rate, ammo_capacity, reload_time }
    }
}
