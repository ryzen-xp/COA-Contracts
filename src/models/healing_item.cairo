use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct HealingItem {
    #[key]
    pub id: felt252,
    pub name: felt252,
    pub description: felt252, 
    pub effect_strength: u16,
    pub consumable: bool,
}

#[generate_trait]
pub impl HealingItemImpl of HealingItemTrait {
    fn get_healing_power(self: @HealingItem) -> u16 {
        *self.effect_strength
    }
}

#[cfg(test)]
mod tests {
    use super::{HealingItem, HealingItemImpl};

    #[test]
    fn test_healing_item_creation() {
        let healing_potion = HealingItem {
            id: 1,
            name: 'Health Potion',
            description: 'Restores health when consumed',
            effect_strength: 25,
            consumable: true,
        };

        assert(healing_potion.id == 1, 'Invalid ID');
        assert(healing_potion.name == 'Health Potion', 'Invalid name');
        assert(healing_potion.effect_strength == 25, 'Invalid effect strength');
        assert(healing_potion.consumable == true, 'Should be consumable');
    }

    #[test]
    fn test_get_healing_power() {
        let healing_potion = HealingItem {
            id: 1,
            name: 'Health Potion',
            description: 'Restores health when consumed',
            effect_strength: 25,
            consumable: true,
        };

        assert(healing_potion.get_healing_power() == 25, 'Invalid healing power');
    }
}