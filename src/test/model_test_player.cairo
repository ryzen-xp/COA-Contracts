// ================================================================================
//                               🚀 Test PlayerTrait 🚀
// -------------------------------------------------------------------------------
// 📌 Purpose : Unit tests for player functionality (init, equip, etc.)
// 👨‍💻 Author  : @ryzen-xp
// ================================================================================

#[cfg(test)]
pub mod tests {
    use coa::models::player::*;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use core::array::ArrayTrait;

    const DEFAULT_HP: u256 = 500;
    pub const DEFAULT_MAX_EQUIPPABLE_SLOT: u32 = 10;
    const WAIST_MAX_SLOTS: u32 = 8;

    fn mock_player_address() -> ContractAddress {
        contract_address_const::<0x1234>()
    }

    fn mock_erc1155_address() -> ContractAddress {
        contract_address_const::<0x5678>()
    }

    fn create_test_player() -> Player {
        Player {
            id: mock_player_address(),
            hp: 0,
            max_hp: 0,
            equipped: array![],
            max_equip_slot: 0,
            rank: Default::default(),
            level: 0,
            xp: 0,
            faction: 'test_faction',
            next_rank_in: 0,
            body: Default::default(),
        }
    }


    #[test]
    fn test_init_contract() {
        let mut player = create_test_player();

        assert(player.max_hp == 0, 'PLAYER_SHOULD_BE_UNINITIALIZED');

        player.init('test');

        assert(player.hp == DEFAULT_HP, 'DEFAULT_PLAYER_HP');
        assert(player.max_hp == DEFAULT_HP, 'PLAYER_MAX_HP_IS_DEFAULT_HP');
        assert(player.max_equip_slot == DEFAULT_MAX_EQUIPPABLE_SLOT, 'DEFAULT_MAX_EQUIPPABLE_SLOT');
        assert(player.rank == Default::default(), 'RANK_IS_DEFAULT');

        let original_hp = player.hp;
        player.init('different_faction');
        assert(player.hp == original_hp, 'REINIT_SHOULD_NOT_CHANGE_HP');
    }

    #[test]
    #[should_panic(expected: ('ZERO PLAYER',))]
    fn test_check_fails_with_zero_address() {
        let player = Player {
            id: contract_address_const::<0x0>(),
            hp: DEFAULT_HP,
            max_hp: DEFAULT_HP,
            equipped: array![],
            max_equip_slot: DEFAULT_MAX_EQUIPPABLE_SLOT,
            rank: Default::default(),
            level: 0,
            xp: 0,
            faction: 'test',
            next_rank_in: 0,
            body: Default::default(),
        };

        player.check();
    }

    #[test]
    fn test_add_xp_no_level_up() {
        let mut player = create_test_player();
        player.init('test_faction');

        let leveled_up = player.add_xp(500);

        assert(!leveled_up, 'SHOULD_NOT_LEVEL_UP');
        assert(player.xp == 500, 'XP_SHOULD_BE_500');
        assert(player.level == 0, 'LEVEL_SHOULD_BE_0');
    }

    #[test]
    fn test_add_xp_with_level_up() {
        let mut player = create_test_player();
        player.init('test_faction');

        let leveled_up = player.add_xp(1500);

        assert(leveled_up, 'SHOULD_LEVEL_UP');
        assert(player.xp == 1500, 'XP_SHOULD_BE_1500');
        assert(player.level == 1, 'LEVEL_SHOULD_BE_1');
    }

    #[test]
    fn test_add_xp_multiple_levels() {
        let mut player = create_test_player();
        player.init('test_faction');

        let leveled_up = player.add_xp(2500);

        assert(leveled_up, 'SHOULD_LEVEL_UP');
        assert(player.xp == 2500, 'XP_SHOULD_BE_2500');
        assert(player.level == 2, 'LEVEL_SHOULD_BE_2');
    }

    #[test]
    fn test_get_xp() {
        let mut player = create_test_player();
        player.init('test_faction');
        player.add_xp(750);

        assert(player.get_xp() == 750, 'XP_SHOULD_BE_750');
    }

    #[test]
    fn test_has_free_inventory_slot_empty() {
        let mut player = create_test_player();
        player.init('test_faction');

        assert(player.has_free_inventory_slot(), 'SHOULD_HAVE_FREE_SLOTS');
    }

    #[test]
    fn test_has_free_inventory_slot_full() {
        let mut player = create_test_player();
        player.init('test_faction');

        // Fill slots
        let mut i = 0;
        while i < DEFAULT_MAX_EQUIPPABLE_SLOT {
            player.equipped.append(i.into());
            i += 1;
        };

        assert(!player.has_free_inventory_slot(), 'SHOULD_NOT_HAVE_FREE_SLOTS');
    }

    #[test]
    fn test_equip_item() {
        let mut player = create_test_player();
        player.init('test_faction');

        let item_id: u256 = u256 { low: 0, high: 0x2000 };

        player.equip(item_id);

        assert(player.equipped.len() == 1, 'SHOULD_HAVE_1_EQUIPPED_ITEM');
        assert(*player.equipped.at(0) == item_id, 'ITEM_SHOULD_BE_IN_LIST');
    }

    #[test]
    #[should_panic(expected: ('INSUFFICIENT EQUIP SLOTS',))]
    fn test_equip_item_insufficient_slots() {
        let mut player = create_test_player();
        player.init('test_faction');

        let mut i = 0;
        while i < DEFAULT_MAX_EQUIPPABLE_SLOT {
            player.equipped.append(i.into());
            i += 1;
        };

        player.equip(99999_u256);
    }

    #[test]
    fn test_receive_damage_normal() {
        let mut player = create_test_player();
        player.init('test_faction');

        let is_alive = player.receive_damage(100);

        assert(is_alive, 'PLAYER_SHOULD_BE_ALIVE');
        assert(player.hp == DEFAULT_HP - 100, 'HP_SHOULD_BE_REDUCED');
    }

    #[test]
    fn test_receive_damage_lethal() {
        let mut player = create_test_player();
        player.init('test_faction');

        let is_alive = player.receive_damage(DEFAULT_HP + 100);

        assert(!is_alive, 'PLAYER_SHOULD_BE_DEAD');
        assert(player.hp == 0, 'HP_SHOULD_BE_0');
    }

    #[test]
    fn test_receive_damage_exact_lethal() {
        let mut player = create_test_player();
        player.init('test_faction');

        let is_alive = player.receive_damage(DEFAULT_HP);

        assert(!is_alive, 'PLAYER_SHOULD_BE_DEAD');
        assert(player.hp == 0, 'HP_SHOULD_BE_0');
    }

    #[test]
    fn test_calculate_damage_reduction_no_armor() {
        let mut player = create_test_player();
        player.init('test_faction');

        let reduction = player.calculate_damage_reduction();
        assert(reduction == 0, 'SHOULD_HAVE_NO_DAMAGE_REDUCTION');
    }

    #[test]
    fn test_calculate_damage_reduction_with_armor() {
        let mut player = create_test_player();
        player.init('test_faction');

        player.body.upper_torso.append(1_u256);
        player.body.lower_torso.append(2_u256);
        player.body.head = 3_u256;

        let reduction = player.calculate_damage_reduction();
        assert(reduction == 18, 'SHOULD_HAVE_18_DAMAGE_REDUCTION');
    }

    #[test]
    fn test_receive_damage_with_armor() {
        let mut player = create_test_player();
        player.init('test_faction');

        player.body.upper_torso.append(1_u256);

        let is_alive = player.receive_damage(50);

        assert(is_alive, 'PLAYER_SHOULD_BE_ALIVE');
        assert(player.hp == DEFAULT_HP - 40, 'HP_SHOULD_BE_REDUCED_BY_40');
    }

    #[test]
    fn test_receive_damage_armor_blocks_all() {
        let mut player = create_test_player();
        player.init('test_faction');

        player.body.upper_torso.append(1_u256);
        player.body.lower_torso.append(2_u256);
        player.body.head = 3_u256;

        let original_hp = player.hp;
        let is_alive = player.receive_damage(15);

        assert(is_alive, 'PLAYER_SHOULD_BE_ALIVE');
        assert(player.hp == original_hp, 'HP_SHOULD_NOT_BE_REDUCED');
    }

    #[test]
    fn test_get_multiplier() {
        let mut player = create_test_player();
        player.init('test_faction');

        let multiplier = player.get_multiplier();
        assert(multiplier == 0, 'MULTIPLIER_SHOULD_BE_0');
    }

    #[test]
    fn test_is_available() {
        let mut player = create_test_player();
        player.init('test_faction');

        let available = player.is_available(123_u256);
        assert(available, 'ITEM_SHOULD_BE_AVAILABLE');
    }

    #[test]
    fn test_helper_functions() {
        let test_val: u256 = 0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0;

        let high = get_high(test_val);
        let low = get_low(test_val);

        assert(high == test_val.high, 'HIGH_BITS_SHOULD_MATCH');
        assert(low == test_val.low, 'LOW_BITS_SHOULD_MATCH');
    }

    #[test]
    fn test_player_progression() {
        let mut player = create_test_player();
        player.init('warrior');

        let leveled_up = player.add_xp(1000);
        assert(leveled_up, 'SHOULD_LEVEL_UP_TO_1');
        assert(player.level == 1, 'LEVEL_SHOULD_BE_1');

        player.equip(u256 { low: 0, high: 0x2000 });
        player.equip(u256 { low: 0, high: 0x105 });
        assert(player.equipped.len() == 2, 'SHOULD_HAVE_2_EQUIPPED_ITEMS');

        let is_alive = player.receive_damage(100);
        assert(is_alive, 'SHOULD_SURVIVE_DAMAGE');
        assert(player.hp < DEFAULT_HP, 'HP_SHOULD_BE_REDUCED');
    }

    #[test]
    fn test_combat_scenario() {
        let mut player = create_test_player();
        player.init('knight');

        player.body.upper_torso.append(1_u256);
        player.body.head = 2_u256;

        let mut is_alive = player.receive_damage(50);
        assert(is_alive, 'SHOULD_SURVIVE_FIRST_HIT');

        is_alive = player.receive_damage(200);
        assert(is_alive, 'SHOULD_SURVIVE_SECOND_HIT');

        let expected_hp = DEFAULT_HP - 37 - 187;
        assert(player.hp == expected_hp, 'HP_CAL_SHOULD_BE_CORRECT');
    }

    #[test]
    fn test_receive_zero_damage() {
        let mut player = create_test_player();
        player.init('test');
        let original_hp = player.hp;

        let is_alive = player.receive_damage(0);

        assert(is_alive, 'PLAYER_SHOULD_BE_ALIVE');
        assert(player.hp == original_hp, 'HP_SHOULD_NOT_CHANGE');
    }

    #[test]
    #[should_panic(expected: ('CANNOT EQUIP',))]
    fn test_equip_same_item_twice() {
        let mut player = create_test_player();
        player.init('test');
        let item_id = u256 { low: 0, high: 0x2000 };

        player.equip(item_id);
        player.equip(item_id);
    }

    #[test]
    fn test_receive_damage_when_dead() {
        let mut player = create_test_player();
        player.init('test');

        player.receive_damage(DEFAULT_HP + 100); // kill
        let is_alive = player.receive_damage(50);

        assert(!is_alive, 'DEAD_PLAYER_SHOULD_REMAIN_DEAD');
        assert(player.hp == 0, 'HP_SHOULD_STAY_ZERO');
    }

    #[test]
    fn test_add_zero_xp() {
        let mut player = create_test_player();
        player.init('test');

        let leveled_up = player.add_xp(0);

        assert(!leveled_up, 'SHOULD_NOT_LEVEL_UP');
        assert(player.xp == 0, 'XP_SHOULD_STILL_BE_0');
        assert(player.level == 0, 'LEVEL_SHOULD_BE_0');
    }
}
