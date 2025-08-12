#[dojo::model]
#[derive(Drop, Copy, Serde)]
pub struct Vehicle {
    #[key]
    pub asset_id: u256,
    pub health: u64,
    pub max_health: u64,
    pub armor: u64,
    pub speed: u64,
    pub fuel_capacity: u64,
    pub current_fuel: u64,
    pub passenger_capacity: u8,
}

#[generate_trait]
pub impl VehicleImpl of VehicleTrait {
    fn init(
        ref self: Vehicle,
        asset_id: u256,
        health: u64,
        armor: u64,
        speed: u64,
        fuel_capacity: u64,
        passenger_capacity: u8,
    ) {
        self.asset_id = asset_id;
        self.health = health;
        self.max_health = health;
        self.armor = armor;
        self.speed = speed;
        self.fuel_capacity = fuel_capacity;
        self.current_fuel = fuel_capacity;
        self.passenger_capacity = passenger_capacity;
    }

    fn apply_damage(ref self: Vehicle, damage: u64) {
        let absorbed_damage = damage * self.armor / 100;
        let net_damage = damage - absorbed_damage;

        if self.health >= net_damage {
            self.health -= net_damage;
        } else {
            self.health = 0;
        }
    }

    fn consume_fuel(ref self: Vehicle, distance: u64) {
        // 1 unit of fuel per 10 units of distance
        let fuel_consumed = distance / 10;
        if self.current_fuel >= fuel_consumed {
            self.current_fuel -= fuel_consumed;
        } else {
            self.current_fuel = 0;
        }
    }

    fn refuel(ref self: Vehicle, amount: u64) {
        self.current_fuel += amount;
        if self.current_fuel > self.fuel_capacity {
            self.current_fuel = self.fuel_capacity;
        }
    }

    fn repair(ref self: Vehicle, amount: u64) {
        self.health += amount;
        if self.health > self.max_health {
            self.health = self.max_health;
        }
    }

    fn is_destroyed(self: @Vehicle) -> bool {
        *self.health == 0
    }

    fn needs_fuel(self: @Vehicle) -> bool {
        *self.current_fuel == 0
    }
}
