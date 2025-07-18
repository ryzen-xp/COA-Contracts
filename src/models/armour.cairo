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
}
