
#[derive(Drop, Serde, Clone)]
#[dojo::model]
pub struct Health {
    #[key]
    pub entity_id: u32,
    pub current: u16,
    pub max: u16,
}

#[generate_trait]
pub impl HealthImpl of HealthTrait {
    fn is_non_zero(self: @Health) -> bool {
        *self.max > 0
    }

    fn is_dead(self: @Health) -> bool {
        *self.current == 0
    }
}

#[generate_trait]
pub impl HealthSystem of HealthSystemTrait {
    
    fn apply_damage( mut self : Health ,  amount: u16)-> Health {
        assert(amount > 0, 'INVALID_DAMAGE');
        assert(self.max > 0,'ENTITY_NOT_FOUND');

        if self.current <= amount {
            self.current = 0;
        } else {
            self.current -= amount;
        }
        self
    }
}


#[cfg(test)]
mod tests {
    use super::{Health, HealthImpl, HealthSystem};

    #[test]
    fn test_apply_partial_damage() {
        let mut health = Health { entity_id: 1, current: 100, max: 100 };
       let health= HealthSystem::apply_damage(health, 30);
        assert(health.current == 70, 'Should reduce HP by 30');
    }

    #[test]
    fn test_apply_fatal_damage() {
        let mut health = Health { entity_id: 2, current: 50, max: 100 };
       let health =  HealthSystem::apply_damage( health,  50);
        assert(health.current == 0, 'HP should 0 after fatal damage');
    }

    #[test]
    fn test_apply_excessive_damage() {
        let mut health = Health { entity_id: 3, current: 20, max: 100 };
        let health = HealthSystem::apply_damage(health, 100);
        assert(health.current == 0, 'HP should not go below zero');
    }

    #[test]
    #[should_panic(expected : ('INVALID_DAMAGE', ))]
    fn test_zero_damage_panics() {
        let mut health = Health { entity_id: 4, current: 100, max: 100 };
        HealthSystem::apply_damage(health,0);
    }

    #[test]
    #[should_panic(expected:('ENTITY_NOT_FOUND',))]
    fn test_entity_not_found_panics() {
        let mut health = Health { entity_id: 5, current: 0, max: 0 };
        HealthSystem::apply_damage(health,10);
    }
}
