use starknet::get_block_timestamp;

#[derive(Drop, Serde, Clone, Introspect)]
#[dojo::model]
pub struct Cooldown {
    #[key]
    pub player_id: u32,
    #[key]
    pub action_type: felt252,
    pub ready_at: u64,
}

#[generate_trait]
impl CooldownLogic of CooldownTrait {
    fn set_cooldown(ref  self :Cooldown,  delay: u64) {
        assert(delay > 0, 'Invalid_delay');
        let current_time = get_block_timestamp(); 
        self.ready_at = current_time + delay;

    }
}

#[cfg(test)]
mod tests {
    use super::{Cooldown, CooldownLogic, CooldownTrait};
    use starknet::testing::set_block_timestamp;

    #[test]
    fn test_new_cooldown_initial_state() {
        let cooldown = Cooldown {
            player_id: 1,
            action_type: 'jump',
            ready_at: 0,
        };

        assert(cooldown.player_id == 1, 'Wrong player ID');
        assert(cooldown.action_type == 'jump', 'Wrong action type');
        assert(cooldown.ready_at == 0, 'Initial ready_at should be 0');
    }

    #[test]
    fn test_set_cooldown_sets_ready_at_correctly() {
        let mut cooldown = Cooldown {
            player_id: 1,
            action_type: 'dash',
            ready_at: 0,
        };

        let fake_time: u64 = 1000;
        let delay: u64 = 300;

        set_block_timestamp(fake_time);
        cooldown.set_cooldown(delay);

        assert(
            cooldown.ready_at == fake_time + delay,
            'set current_time + delay',
        );
    }

    #[test]
    #[should_panic(expected : 'Invalid_delay')]
    fn test_set_cooldown_with_zero_delay_panics() {
        let mut cooldown = Cooldown {
            player_id: 2,
            action_type: 'attack',
            ready_at: 0,
        };

        cooldown.set_cooldown(0);
    }

    #[test]
    fn test_multiple_cooldowns_different_players() {
        let mut c1 = Cooldown {
            player_id: 1,
            action_type: 'jump',
            ready_at: 0,
        };

        let mut c2 = Cooldown {
            player_id: 2,
            action_type: 'jump',
            ready_at: 0,
        };

        set_block_timestamp(500);
        c1.set_cooldown(200);

        set_block_timestamp(1000);
        c2.set_cooldown(100);

        assert(c1.ready_at == 700, 'Player 1 cooldown 700');
        assert(c2.ready_at == 1100, 'Player 2 cooldown 1100');
    }
}
