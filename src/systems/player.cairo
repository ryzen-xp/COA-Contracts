use crate::models::{player::Player};

#[starknet::interface]
pub trait IPlayer<TContractState> {
    fn new(ref self: TContractState, faction: felt252);
    fn deal_damage(
        ref self: TContractState,
        target: Array<u256>,
        target_types: Array<felt252>,
        with_items: Array<u256>,
    );
    fn get_player(self: @TContractState, player_id: u256) -> Player;
    fn register_guild(ref self: TContractState);
}

#[dojo::contract]
pub mod PlayerActions {
    use starknet::{ContractAddress, get_caller_address};
    use crate::models::player::{Player, PlayerTrait};
    use crate::models::gear::{Gear, GearTrait};
    use super::IPlayer;
    use dojo::model::{ModelStorage};

    // Faction types as felt252 constants
    const CHAOS_MERCENARIES: felt252 = 'CHAOS_MERCENARIES';
    const SUPREME_LAW: felt252 = 'SUPREME_LAW';
    const REBEL_TECHNOMANCERS: felt252 = 'REBEL_TECHNOMANCERS';

    // Target types as felt252 constants
    const TARGET_LIVING: felt252 = 'LIVING';
    const TARGET_OBJECT: felt252 = 'OBJECT';

    #[derive(Copy, Drop, Serde)]
    struct FactionStats {
        damage_multiplier: u256,
        defense_multiplier: u256,
        speed_multiplier: u256,
    }

    // const GEAR_
    const MIN_THRESHOLD: u32 = 80;


    fn dojo_init(
        ref self: ContractState, admin: ContractAddress, default_amount_of_credits: u256,
    ) { // write admin
    // write default amount of credits.

    }

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayer<ContractState> {
        fn new(ref self: ContractState, faction: felt252) { // create the player
        // and call mint
        // maybe in the future, you implement a `mint_default()`
        // spawn player at some random location.
        }

        fn deal_damage(
            ref self: ContractState,
            target: Array<u256>,
            target_types: Array<felt252>,
            with_items: Array<u256>,
        ) { // check if the player and the items exists..
            // assert that the items are something that can deal damage
            // from no. 2, not just assert, handle appropriately, but do not panic
            // factor in the faction type and add additional damage
            // factor in the weapon type and xp // rank trait.
            // and factor in the item type, if the item has been upgraded
            // check if the item has been equipped
            // to find out the item's output when upgraded, call the item.output(val), where val is
            // the upgraded level.

            // if with_items.len() is zero, then it's a normal melee attack.

            // factor in the target's damage factor... might later turn out not to be damaged
            // this means that each target or item should have a damage factor, and might cause
            // credits to be repaired

            // for the target, the above is if the target_type is an object.
            // if the target type is a living organism, check all the eqippable traits
            // this means that the PlayerTrait should have a recieve_damage,

            // or recieve damage should probably be an internal trait for now.

            let world = self.world_default();
            let caller = get_caller_address();
            // get the player
            let player: Player = world.read_model(caller);

            // Validate input arrays have same length
            assert(target.len() == target_types.len(), 'Target arrays length mismatch');

            let mut target_index = 0;

            // Calculate faction bonuses
            let faction_stats = self.get_faction_stats(player.faction);

            loop {
                if target_index >= target.len() {
                    break;
                }

                let target_id = *target.at(target_index);
                let target_type = *target_types.at(target_index);

                // Calculate base damage
                let mut total_damage = 0;

                if with_items.len() == 0 {
                    // Normal melee attack
                    total_damage = self.calculate_melee_damage(player.clone(), faction_stats);
                } else {
                    // Weapon-based attack
                    total_damage = self
                        .calculate_weapon_damage(player.clone(), with_items.span(), faction_stats);
                }

                // Apply the damage
                self.damage_target(target_id, target_type, total_damage);
                target_index += 1;
            };
        }

        fn get_player(self: @ContractState, player_id: u256) -> Player {
            Default::default()
        }
        fn register_guild(ref self: ContractState) {}
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"coa")
        }
        fn get_faction_stats(self: @ContractState, faction: felt252) -> FactionStats {
            if faction == CHAOS_MERCENARIES {
                FactionStats {
                    damage_multiplier: 120, // +20% damage
                    defense_multiplier: 100,
                    speed_multiplier: 100,
                }
            } else if faction == SUPREME_LAW {
                FactionStats {
                    damage_multiplier: 100,
                    defense_multiplier: 125, // +25% defense
                    speed_multiplier: 100,
                }
            } else if faction == REBEL_TECHNOMANCERS {
                FactionStats {
                    damage_multiplier: 100,
                    defense_multiplier: 100,
                    speed_multiplier: 115 // +15% speed (simplified for now)
                }
            } else {
                // Default/no faction
                FactionStats {
                    damage_multiplier: 100, defense_multiplier: 100, speed_multiplier: 100,
                }
            }
        }
        fn calculate_melee_damage(
            self: @ContractState, player: Player, faction_stats: FactionStats,
        ) -> u256 {
            // Base weapon damage from player stats
            let base_damage = 10 + (player.level / 100); // Simple Level scaling

            // Apply faction damage multiplier
            let faction_damage = (base_damage * faction_stats.damage_multiplier) / 100;

            // Factor in player rank/level
            let rank_multiplier = 100 + (player.rank.into() * 5); // 5% per rank
            let final_damage = (faction_damage * rank_multiplier) / 100;

            final_damage
        }

        fn calculate_weapon_damage(
            self: @ContractState, player: Player, items: Span<u256>, faction_stats: FactionStats,
        ) -> u256 {
            let world = self.world_default();
            let mut total_damage = 0;
            let mut item_index = 0;

            loop {
                if item_index >= items.len() {
                    break;
                }

                let item_id = *items.at(item_index);

                // Get the item
                let item: Gear = world.read_model(item_id);

                // Check that item can deal damage
                if !self.can_deal_damage(item.clone()) {
                    continue;
                }

                // Check that item is equipped
                if !player.is_available(item.id) {
                    continue;
                }

                //
                // Calculate item damage with upgrades
                let base_item_damage = self.get_item_base_damage(item.item_type);
                let upgraded_damage = if item.upgrade_level > 0 {
                    item.output(item.upgrade_level)
                } else {
                    base_item_damage
                };

                // Apply weapon type damage multiplier
                let weapon_multiplier = self.get_weapon_type_damage_multiplier(item.item_type);
                let weapon_damage = (upgraded_damage * weapon_multiplier) / 100;

                total_damage += weapon_damage;
                item_index += 1;
            };

            // Apply faction damage multiplier
            let faction_damage = (total_damage * faction_stats.damage_multiplier) / 100;

            // Factor in player XP and rank
            let xp_bonus = (player.level / 50); // XP bonus
            let rank_multiplier = 100 + (player.rank.into() * 5);
            let final_damage = ((faction_damage + xp_bonus) * rank_multiplier) / 100;

            final_damage
        }

        fn can_deal_damage(self: @ContractState, item: Gear) -> bool {
            // Custom Logic here
            true
        }

        fn get_item_base_damage(self: @ContractState, item_type: felt252) -> u256 {
            // TODO: add proper logic for damage calculation when item types are defined.
            20
        }

        fn get_weapon_type_damage_multiplier(self: @ContractState, item_type: felt252) -> u256 {
            // TODO: add proper logic for weapon damage percentage
            110 // 10% added damage
        }

        fn damage_target(
            ref self: ContractState, target_id: u256, target_type: felt252, damage: u256,
        ) {
            if target_type == TARGET_LIVING {
                let mut target = self.get_player(target_id);
                target.receive_damage(damage);
            } else { // TODO: Implement the damage trait to object after game objects are defined.
            }
        }
    }
}
