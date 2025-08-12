#[dojo::model]
#[derive(Drop, Copy, Serde)]
pub struct BluntWeapon {
    #[key]
    pub asset_id: u256,
    pub damage: u64,
    pub speed: u64,
    pub stun_chance: u8,
    pub durability: u64,
    pub max_durability: u64,
}

#[generate_trait]
pub impl BluntWeaponImpl of BluntWeaponTrait {
    fn init(
        ref self: BluntWeapon,
        asset_id: u256,
        damage: u64,
        speed: u64,
        stun_chance: u8,
        durability: u64,
    ) {
        self.asset_id = asset_id;
        self.damage = damage;
        self.speed = speed;
        self.stun_chance = stun_chance;
        self.durability = durability;
        self.max_durability = durability;
    }

    fn calculate_dps(self: @BluntWeapon) -> u64 {
        (*self.damage * *self.speed) / 100
    }

    fn apply_wear(ref self: BluntWeapon, amount: u64) {
        if self.durability >= amount {
            self.durability -= amount;
        } else {
            self.durability = 0;
        }
    }

    fn repair(ref self: BluntWeapon, amount: u64) {
        self.durability += amount;
        if self.durability > self.max_durability {
            self.durability = self.max_durability;
        }
    }

    fn is_broken(self: @BluntWeapon) -> bool {
        *self.durability == 0
    }
}
