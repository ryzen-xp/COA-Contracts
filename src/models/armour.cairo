use crate::types::player::StatBonus;

#[dojo::model]
#[derive(Drop, Clone, Serde, Debug, Default)]
pub struct Armour {
    #[key]
    pub id: u256,
    pub item_type: u64,
    pub name: felt252,
    pub level: u256,
    pub stat_bonus: StatBonus,
    pub special_effect: felt252,
    pub is_utilized: bool,
    pub damage_reduction: u128, // Percentage of damage reduced (0-100)
    pub durability: u64, // Current durability
    pub max_durability: u64,
}

#[generate_trait]
pub impl ArmourImpl of ArmourTrait {
    fn init(ref self: Armour, id: u256, item_type: u64, name: felt252, level: u256) {
        self.id = id;
        self.item_type = item_type;
        self.name = name;
        self.level = level;
        self.stat_bonus = StatBonus { strength: 0, vitality: 0, luck: 0 };
        self.special_effect = 0;
        self.is_utilized = false;
    }

    fn set_stat_bonus(ref self: Armour, strength: u64, vitality: u64, luck: u64) {
        self.stat_bonus = StatBonus { strength, vitality, luck };
    }

    fn set_special_effect(ref self: Armour, effect: felt252) {
        self.special_effect = effect;
    }

    fn utilize(ref self: Armour) {
        self.is_utilized = true;
    }

    fn is_equippable(self: @Armour) -> bool {
        // Armour is not equippable_on as specified
        false
    }

    fn get_total_bonus(self: Armour) -> u64 {
        self.stat_bonus.strength + self.stat_bonus.vitality + self.stat_bonus.luck
    }

    fn calculate_damage_reduction(self: @Armour, damage: u128) -> u128 {
        if *self.is_utilized {
            return damage;
        }

        let reduction = (damage * (*self.damage_reduction)) / 100;
        damage - reduction
    }

    fn apply_damage(ref self: Armour, damage: u128) -> u128 {
        let remaining_damage = self.calculate_damage_reduction(damage);

        if self.durability > 0 {
            let durability_loss = if remaining_damage > self.durability.into() {
                self.durability
            } else {
                remaining_damage.try_into().unwrap_or(0)
            };
            self.durability -= durability_loss;
        }

        remaining_damage
    }
}
