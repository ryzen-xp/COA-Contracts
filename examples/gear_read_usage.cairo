// Example usage of Gear Read Operations
// This file demonstrates how to use the comprehensive gear read system

use crate::systems::gear::GearActions;
use crate::interfaces::gear::IGear;
use crate::models::gear::{
    GearType, GearFilters, OwnershipFilter, PaginationParams, SortParams, SortField,
};
use starknet::{ContractAddress, contract_address_const};

// Example 1: Get detailed information about a specific item
fn example_get_item_details(
    gear_system: IGear<GearActions::ContractState>, item_id: u256, session_id: felt252,
) {
    let item_details = gear_system.get_gear_details_complete(item_id, session_id);

    match item_details {
        Option::Some(details) => {
            // Access basic gear information
            let gear = details.gear;
            println!("Item ID: {}", gear.id);
            println!("Type: {}", gear.item_type);
            println!("Level: {}", gear.upgrade_level);
            println!("Max Level: {}", gear.max_upgrade_level);

            // Access calculated stats
            let stats = details.calculated_stats;
            println!("Damage: {}", stats.damage);
            println!("Defense: {}", stats.defense);
            println!("Range: {}", stats.range);

            // Check upgrade information
            match details.upgrade_info {
                Option::Some(upgrade_info) => {
                    if upgrade_info.can_upgrade {
                        println!("Can upgrade to level: {}", upgrade_info.current_level + 1);
                        match upgrade_info.success_rate {
                            Option::Some(rate) => println!("Success rate: {}%", rate),
                            Option::None => println!("Success rate not available"),
                        }
                    } else {
                        println!("Item is at maximum level");
                    }
                },
                Option::None => println!("No upgrade information available"),
            }

            // Check ownership status
            let ownership = details.ownership_status;
            if ownership.is_owned {
                println!("Owned by: {}", ownership.owner);
            } else if ownership.is_available_for_pickup {
                println!("Available for pickup");
            }
        },
        Option::None => { println!("Item not found or invalid session"); },
    }
}

// Example 2: Browse player inventory with filtering and sorting
fn example_browse_inventory(
    gear_system: IGear<GearActions::ContractState>, player: ContractAddress, session_id: felt252,
) {
    // Create filters for weapons and armor above level 3
    let filters = GearFilters {
        gear_types: Option::Some(
            array![
                GearType::Weapon,
                GearType::Sword,
                GearType::Bow,
                GearType::Firearm,
                GearType::ChestArmor,
                GearType::Helmet,
            ],
        ),
        min_level: Option::Some(3),
        max_level: Option::None,
        ownership_filter: Option::Some(OwnershipFilter::Owned),
        min_xp_required: Option::None,
        max_xp_required: Option::None,
        spawned_only: Option::None,
    };

    // Set up pagination (50 items per page)
    let pagination = PaginationParams { offset: 0, limit: 50 };

    // Sort by damage (highest first)
    let sort = SortParams { sort_by: SortField::Damage, ascending: false };

    let inventory_result = gear_system
        .get_player_inventory(
            player, Option::Some(filters), Option::Some(pagination), Option::Some(sort), session_id,
        );

    println!("Found {} items", inventory_result.total_count);
    println!("Showing {} items", inventory_result.items.len());

    let mut i = 0;
    while i < inventory_result.items.len() {
        let item = inventory_result.items.at(i);
        let gear = item.gear;
        let stats = item.calculated_stats;

        println!(
            "Item {}: Level {} {} - Damage: {}, Defense: {}",
            gear.id,
            gear.upgrade_level,
            gear.item_type,
            stats.damage,
            stats.defense,
        );
        i += 1;
    };

    if inventory_result.has_more {
        println!("More items available - use pagination to load more");
    }
}

// Example 3: Plan an upgrade strategy
fn example_upgrade_planning(
    gear_system: IGear<GearActions::ContractState>,
    item_id: u256,
    target_level: u64,
    session_id: felt252,
) {
    // Get upgrade preview
    let upgrade_preview = gear_system.get_upgrade_preview(item_id, target_level, session_id);

    match upgrade_preview {
        Option::Some(preview) => {
            println!("Upgrade from level {} to level {}", preview.current_level, target_level);

            // Show stats improvement
            match preview.next_level_stats {
                Option::Some(new_stats) => {
                    // Get current stats for comparison
                    let current_stats = gear_read_system.get_calculated_stats(item_id, session_id);
                    match current_stats {
                        Option::Some(current) => {
                            let damage_increase = new_stats.damage - current.damage;
                            let defense_increase = new_stats.defense - current.defense;

                            println!("Damage increase: +{}", damage_increase);
                            println!("Defense increase: +{}", defense_increase);
                        },
                        Option::None => println!("Could not get current stats"),
                    }
                },
                Option::None => println!("Preview stats not available"),
            }

            // Calculate total upgrade costs
            let total_costs = gear_system
                .calculate_upgrade_costs(item_id, target_level, session_id);
            match total_costs {
                Option::Some(costs) => {
                    println!("Required materials:");
                    let mut i = 0;
                    while i < costs.len() {
                        let (token_id, amount) = *costs.at(i);
                        println!("Token {}: {} units", token_id, amount);
                        i += 1;
                    };

                    // Check if player has materials (example materials)
                    let player_materials = array![
                        (1_u256, 1000_u256), // Scrap metal
                        (2_u256, 500_u256), // Wiring
                        (3_u256, 100_u256) // Advanced alloy
                    ];

                    let (feasible, missing) = gear_system
                        .check_upgrade_feasibility(
                            item_id, target_level, player_materials, session_id,
                        );

                    if feasible {
                        println!("Upgrade is feasible with current materials!");
                    } else {
                        println!("Missing materials:");
                        let mut j = 0;
                        while j < missing.len() {
                            let (token_id, amount) = *missing.at(j);
                            println!("Need {} more of token {}", amount, token_id);
                            j += 1;
                        };
                    }
                },
                Option::None => println!("Could not calculate upgrade costs"),
            }
        },
        Option::None => { println!("Cannot upgrade to level {} or item not found", target_level); },
    }
}

// Example 4: Find items available for pickup
fn example_find_available_items(
    gear_system: IGear<GearActions::ContractState>, player_xp: u256, session_id: felt252,
) {
    // Filter for weapons that the player can pick up
    let filters = GearFilters {
        gear_types: Option::Some(
            array![GearType::Weapon, GearType::Sword, GearType::Bow, GearType::Firearm],
        ),
        min_level: Option::None,
        max_level: Option::None,
        ownership_filter: Option::Some(OwnershipFilter::Available),
        min_xp_required: Option::None,
        max_xp_required: Option::Some(player_xp), // Only items player can pick up
        spawned_only: Option::Some(true),
    };

    let pagination = PaginationParams { offset: 0, limit: 20 };

    let available_items = gear_system
        .get_available_items(
            player_xp, Option::Some(filters), Option::Some(pagination), session_id,
        );

    println!("Available items for pickup:");
    println!("Player XP: {}", player_xp);

    let mut i = 0;
    while i < available_items.items.len() {
        let item = available_items.items.at(i);
        let gear = item.gear;
        let stats = item.calculated_stats;

        println!(
            "Item {}: {} (Level {}) - Damage: {}, XP Required: {}",
            gear.id,
            gear.item_type,
            gear.upgrade_level,
            stats.damage,
            gear.min_xp_needed,
        );
        i += 1;
    };
}

// Example 5: Compare multiple items
fn example_compare_items(
    gear_system: IGear<GearActions::ContractState>, item_ids: Array<u256>, session_id: felt252,
) {
    let stats_comparison = gear_system.compare_gear_stats(item_ids, session_id);

    println!("Item comparison:");
    let mut i = 0;
    while i < stats_comparison.len() {
        let stats = stats_comparison.at(i);
        let item_id = *item_ids.at(i);

        println!(
            "Item {}: Damage: {}, Defense: {}, Range: {}",
            item_id,
            stats.damage,
            stats.defense,
            stats.range,
        );
        i += 1;
    };
}

// Example 6: Get equipped gear overview
fn example_equipped_gear_overview(
    gear_system: IGear<GearActions::ContractState>, player: ContractAddress, session_id: felt252,
) {
    let equipped_effects = gear_system.get_equipped_gear(player, session_id);

    println!("Equipped gear overview:");
    println!("Total damage: {}", equipped_effects.total_damage);
    println!("Total defense: {}", equipped_effects.total_defense);
    println!("Total weight: {}", equipped_effects.total_weight);

    println!("Equipped slots:");
    let mut i = 0;
    while i < equipped_effects.equipped_slots.len() {
        let slot = equipped_effects.equipped_slots.at(i);
        match slot.equipped_item {
            Option::Some(gear) => {
                println!(
                    "Slot {}: Item {} (Level {})", slot.slot_type, gear.id, gear.upgrade_level,
                );
            },
            Option::None => { println!("Slot {}: Empty", slot.slot_type); },
        }
        i += 1;
    };

    println!("Set bonuses:");
    let mut j = 0;
    while j < equipped_effects.set_bonuses.len() {
        let (bonus_type, bonus_value) = *equipped_effects.set_bonuses.at(j);
        println!("Bonus {}: +{}", bonus_type, bonus_value);
        j += 1;
    };
}

// Example 7: Efficient batch operations
fn example_batch_operations(
    gear_system: IGear<GearActions::ContractState>, item_ids: Array<u256>, session_id: felt252,
) {
    // Get details for multiple items in one call
    let batch_details = gear_system.get_gear_details_batch(item_ids, session_id);

    println!("Batch item details:");
    let mut i = 0;
    while i < batch_details.len() {
        match batch_details.at(i) {
            Option::Some(details) => {
                let gear = details.gear;
                println!("Item {}: Level {} {}", gear.id, gear.upgrade_level, gear.item_type);
            },
            Option::None => {
                let item_id = *item_ids.at(i);
                println!("Item {}: Not found or inaccessible", item_id);
            },
        }
        i += 1;
    };
}

// Example usage in a game context
fn example_game_integration() {
    // This would be called from your game's main systems
    let player = contract_address_const::<0x123>();
    let session_id = 'player_session_123';

    // Example: Player wants to see their inventory
    // example_browse_inventory(gear_read_system, player, session_id);

    // Example: Player wants to plan an upgrade
    let sword_id = 12345_u256;
    // example_upgrade_planning(gear_read_system, sword_id, 8, session_id);

    // Example: Player wants to find new items to pick up
    let player_xp = 5000_u256;
    // example_find_available_items(gear_read_system, player_xp, session_id);
}
