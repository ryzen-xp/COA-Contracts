#[dojo::model]
#[derive(Drop, Copy, Serde)]
pub struct Bow {
    #[key]
    pub asset_id: u256,
    pub damage: u64,
    pub range: u64,
    pub draw_speed: u64,
    pub accuracy: u8,
}

#[generate_trait]
pub impl BowImpl of BowTrait {
    fn init(ref self: Bow, asset_id: u256, damage: u64, range: u64, draw_speed: u64, accuracy: u8) {
        self.asset_id = asset_id;
        self.damage = damage;
        self.range = range;
        self.draw_speed = draw_speed;
        self.accuracy = accuracy;
    }

    fn get_effective_range_damage(self: @Bow, distance: u64) -> u64 {
        if distance > *self.range {
            0
        } else {
            // Linear damage falloff
            *self.damage - (*self.damage * distance / *self.range) / 2
        }
    }
}
