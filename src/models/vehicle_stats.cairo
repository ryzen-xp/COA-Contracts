#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct VehicleStats {
    #[key]
    pub asset_id: u256,
    pub speed: u64,
    pub armor: u64,
    pub fuel_capacity: u64,
    pub cargo_capacity: u64,
    pub maneuverability: u64,
}

#[generate_trait]
pub impl VehicleStatsImpl of VehicleStatsTrait {
    fn new(
        asset_id: u256,
        speed: u64,
        armor: u64,
        fuel_capacity: u64,
        cargo_capacity: u64,
        maneuverability: u64,
    ) -> VehicleStats {
        VehicleStats { asset_id, speed, armor, fuel_capacity, cargo_capacity, maneuverability }
    }
}
