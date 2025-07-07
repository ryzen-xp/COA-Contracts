use crate::models::player::Player;

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
    use super::IPlayer;

    // Faction types as felt252 constants
    const CHAOS_MERCENARIES: felt252 = 'CHAOS_MERCENARIES';
    const SUPREME_LAW: felt252 = 'SUPREME_LAW';
    const REBEL_TECHNOMANCERS: felt252 = 'REBEL_TECHNOMANCERS';

    #[derive(Copy, Drop, Serde)]
    struct FactionStats {
        damage_multiplier: u256,
        defense_multiplier: u256,
        speed_multiplier: u256,
    }

    // const GEAR_

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
        // to find out the item's output when upgraded, call the item.output(val), where val is the
        // upgraded level.

        // if with_items.len() is zero, then it's a normal melee attack.

        // factor in the target's damage factor... might later turn out not to be damaged
        // this means that each target or item should have a damage factor, and might cause credits
        // to be repaired

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
        
        let mut results = array![];
        let mut target_index = 0;
        }

        fn get_player(self: @ContractState, player_id: u256) -> Player {
            Default::default()
        }
        fn register_guild(ref self: ContractState) {}
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
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
                    speed_multiplier: 115, // +15% speed (simplified for now)
                }
            } else {
                // Default/no faction
                FactionStats {
                    damage_multiplier: 100,
                    defense_multiplier: 100,
                    speed_multiplier: 100,
                }
            }
        }
        fn calculate_base_weapon_damage(
            self: @ContractState, 
            player: Player, 
            faction_stats: FactionStats
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
    }
}
