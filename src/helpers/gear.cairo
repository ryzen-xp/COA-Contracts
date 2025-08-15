use starknet::ContractAddress;
use dojo::world::WorldStorage;
use dojo::model::ModelStorage;
use crate::models::gear::{Gear, GearType, GearLevelStats};
use crate::models::weapon_stats::WeaponStats;
use crate::models::armor_stats::Armor;
use crate::models::vehicle_stats::VehicleStats;
use crate::models::pet_stats::PetStats;
use crate::models::gear::{GearStatsCalculated, OwnershipFilter, SortField, PaginationParams};
use core::num::traits::Zero;

// Helper function to calculate upgrade multipliers based on level
pub fn calculate_level_multiplier(level: u64) -> u64 {
    // Base multiplier starts at 100% (level 0) and increases by 10% per level
    100 + (level * 10)
}

// Helper function to apply upgrade multipliers to base stats
pub fn apply_upgrade_multiplier(base_stat: u64, level: u64) -> u64 {
    let multiplier = calculate_level_multiplier(level);
    (base_stat * multiplier) / 100
}

// Enhanced stats calculation with proper multipliers
pub fn calculate_enhanced_gear_stats(world: @WorldStorage, gear: @Gear) -> GearStatsCalculated {
    // Get base level stats
    let level_stats: GearLevelStats = world.read_model((*gear.asset_id, *gear.upgrade_level));

    // Initialize calculated stats
    let mut calculated = GearStatsCalculated {
        damage: level_stats.damage,
        range: level_stats.range,
        accuracy: level_stats.accuracy,
        fire_rate: level_stats.fire_rate,
        defense: level_stats.defense,
        durability: level_stats.durability,
        weight: level_stats.weight,
        speed: 0,
        armor: 0,
        fuel_capacity: 0,
        loyalty: 0,
        intelligence: 0,
        agility: 0,
    };

    // Get gear type and enhance with specific stats
    let gear_type = parse_id(*gear.asset_id);

    match gear_type {
        GearType::Weapon | GearType::BluntWeapon | GearType::Sword | GearType::Bow |
        GearType::Firearm | GearType::Polearm | GearType::HeavyFirearms |
        GearType::Explosives => {
            let weapon_stats: WeaponStats = world.read_model(*gear.asset_id);
            // Apply upgrade multipliers to weapon stats
            calculated.damage = apply_upgrade_multiplier(weapon_stats.damage, *gear.upgrade_level);
            calculated.range = apply_upgrade_multiplier(weapon_stats.range, *gear.upgrade_level);
            calculated
                .accuracy = apply_upgrade_multiplier(weapon_stats.accuracy, *gear.upgrade_level);
            calculated
                .fire_rate = apply_upgrade_multiplier(weapon_stats.fire_rate, *gear.upgrade_level);
        },
        GearType::Helmet | GearType::ChestArmor | GearType::LegArmor | GearType::Boots |
        GearType::Gloves |
        GearType::Shield => {
            let armor_stats: Armor = world.read_model(*gear.asset_id);
            // Apply upgrade multipliers to armor stats
            calculated.defense = apply_upgrade_multiplier(armor_stats.defense, *gear.upgrade_level);
            calculated
                .durability = apply_upgrade_multiplier(armor_stats.durability, *gear.upgrade_level);
            calculated.weight = armor_stats.weight; // Weight doesn't scale with upgrades
        },
        GearType::Vehicle => {
            let vehicle_stats: VehicleStats = world.read_model(*gear.asset_id);
            // Apply upgrade multipliers to vehicle stats
            calculated.speed = apply_upgrade_multiplier(vehicle_stats.speed, *gear.upgrade_level);
            calculated.armor = apply_upgrade_multiplier(vehicle_stats.armor, *gear.upgrade_level);
            calculated
                .fuel_capacity =
                    apply_upgrade_multiplier(vehicle_stats.fuel_capacity, *gear.upgrade_level);
        },
        GearType::Pet |
        GearType::Drone => {
            let pet_stats: PetStats = world.read_model(*gear.asset_id);
            // Apply upgrade multipliers to pet stats
            calculated.loyalty = apply_upgrade_multiplier(pet_stats.loyalty, *gear.upgrade_level);
            calculated
                .intelligence =
                    apply_upgrade_multiplier(pet_stats.intelligence, *gear.upgrade_level);
            calculated.agility = apply_upgrade_multiplier(pet_stats.agility, *gear.upgrade_level);
        },
        _ => { // Default case - use level stats as-is
        },
    }

    calculated
}

// Helper function to check if gear matches ownership filter
pub fn matches_ownership_filter(
    gear: @Gear, filter: OwnershipFilter, player: Option<ContractAddress>,
) -> bool {
    match filter {
        OwnershipFilter::Owned => {
            match player {
                Option::Some(p) => *gear.owner == p,
                Option::None => !gear.owner.is_zero(),
            }
        },
        OwnershipFilter::NotOwned => gear.owner.is_zero(),
        OwnershipFilter::Available => *gear.spawned && gear.owner.is_zero(),
        OwnershipFilter::Equipped => *gear.in_action,
        OwnershipFilter::All => true,
    }
}

// Helper function to check if gear matches type filter
pub fn matches_gear_type_filter(gear: @Gear, allowed_types: @Array<GearType>) -> bool {
    if allowed_types.len() == 0 {
        return true;
    }

    let gear_type = parse_id(*gear.asset_id);
    let mut i = 0;
    let mut match_status = false;
    while i < allowed_types.len() {
        if gear_type == *allowed_types.at(i) {
            match_status = true;
        }
        i += 1;
    };

    match_status
}

// Helper function to check if gear matches level range
pub fn matches_level_range(gear: @Gear, min_level: Option<u64>, max_level: Option<u64>) -> bool {
    let level = *gear.upgrade_level;

    let min_check = match min_level {
        Option::Some(min) => level >= min,
        Option::None => true,
    };

    let max_check = match max_level {
        Option::Some(max) => level <= max,
        Option::None => true,
    };

    min_check && max_check
}

// Helper function to check if gear matches XP requirements
pub fn matches_xp_range(gear: @Gear, min_xp: Option<u256>, max_xp: Option<u256>) -> bool {
    let xp_needed = *gear.min_xp_needed;

    let min_check = match min_xp {
        Option::Some(min) => xp_needed >= min,
        Option::None => true,
    };

    let max_check = match max_xp {
        Option::Some(max) => xp_needed <= max,
        Option::None => true,
    };

    min_check && max_check
}

// Helper function to calculate gear power score for sorting
pub fn calculate_gear_power_score(stats: @GearStatsCalculated) -> u64 {
    // Simple power calculation - can be enhanced based on game balance
    (*stats.damage * 2) + (*stats.defense * 2) + (*stats.range / 2) + (*stats.accuracy / 2)
}

// Helper function to get gear sort value based on sort field
pub fn get_gear_sort_value(gear: @Gear, stats: @GearStatsCalculated, sort_field: SortField) -> u64 {
    match sort_field {
        SortField::Level => *gear.upgrade_level,
        SortField::Damage => *stats.damage,
        SortField::Defense => *stats.defense,
        SortField::XpRequired => {
            // Convert u256 to u64 for sorting (truncate if necessary)
            (*gear.min_xp_needed).try_into().unwrap_or(0)
        },
        SortField::AssetId => {
            // Use low part of asset_id for sorting
            (*gear.asset_id).try_into().unwrap_or(0)
        },
    }
}

// Helper function to validate pagination parameters
pub fn validate_pagination_params(pagination: @PaginationParams) -> bool {
    *pagination.limit > 0 && *pagination.limit <= 1000 // Max 1000 items per page
}

// Helper function to calculate equipment set bonuses
pub fn calculate_set_bonuses(equipped_gear: @Array<Gear>) -> Array<(felt252, u64)> {
    let mut bonuses: Array<(felt252, u64)> = array![];

    // Count gear types
    let mut weapon_count: u32 = 0;
    let mut armor_count: u32 = 0;
    let mut vehicle_count: u32 = 0;

    let mut i = 0;
    while i < equipped_gear.len() {
        let gear = equipped_gear.at(i);
        let gear_type = parse_id(*gear.asset_id);

        match gear_type {
            GearType::Weapon | GearType::BluntWeapon | GearType::Sword | GearType::Bow |
            GearType::Firearm | GearType::Polearm | GearType::HeavyFirearms |
            GearType::Explosives => { weapon_count += 1; },
            GearType::Helmet | GearType::ChestArmor | GearType::LegArmor | GearType::Boots |
            GearType::Gloves | GearType::Shield => { armor_count += 1; },
            GearType::Vehicle => { vehicle_count += 1; },
            _ => {},
        }
        i += 1;
    };

    // Calculate set bonuses
    if armor_count >= 3 {
        bonuses.append(('ARMOR_SET_DEFENSE', 20)); // +20% defense for 3+ armor pieces
    }

    if armor_count >= 5 {
        bonuses.append(('FULL_ARMOR_SET', 50)); // +50% defense for full armor set
    }

    if weapon_count >= 2 {
        bonuses.append(('DUAL_WIELD', 15)); // +15% damage for dual wielding
    }

    bonuses
}

// Helper function to get equipment slot type from gear type
pub fn get_equipment_slot_type(gear_type: GearType) -> felt252 {
    match gear_type {
        GearType::Helmet => 'HEAD',
        GearType::ChestArmor => 'CHEST',
        GearType::LegArmor => 'LEGS',
        GearType::Boots => 'FEET',
        GearType::Gloves => 'HANDS',
        GearType::Shield => 'SHIELD',
        GearType::Weapon | GearType::BluntWeapon | GearType::Sword | GearType::Bow |
        GearType::Firearm | GearType::Polearm | GearType::HeavyFirearms |
        GearType::Explosives => 'WEAPON',
        GearType::Vehicle => 'VEHICLE',
        GearType::Pet => 'PET',
        GearType::Drone => 'DRONE',
        _ => 'NONE',
    }
}


// Helper function to get the high 128 bits from a u256
fn get_high(val: u256) -> u128 {
    val.high
}

pub fn parse_id(id: u256) -> GearType {
    let category = get_high(id);

    // Match the high bits to determine the gear type
    if category == 0x1 {
        GearType::Weapon
    } else if category == 0x101 {
        GearType::BluntWeapon
    } else if category == 0x102 {
        GearType::Sword
    } else if category == 0x103 {
        GearType::Bow
    } else if category == 0x104 {
        GearType::Firearm
    } else if category == 0x105 {
        GearType::Polearm
    } else if category == 0x106 {
        GearType::HeavyFirearms
    } else if category == 0x107 {
        GearType::Explosives
    } else if category == 0x2000 {
        GearType::Helmet
    } else if category == 0x2001 {
        GearType::ChestArmor
    } else if category == 0x2002 {
        GearType::LegArmor
    } else if category == 0x2003 {
        GearType::Boots
    } else if category == 0x2004 {
        GearType::Gloves
    } else if category == 0x2005 {
        GearType::Shield
    } else if category == 0x30000 {
        GearType::Vehicle
    } else if category == 0x800000 {
        GearType::Pet
    } else if category == 0x800001 {
        GearType::Drone
    } else {
        GearType::None // Fungible tokens or invalid
    }
}

pub fn count_gear_in_array(array: Array<u256>, gear_type: GearType) -> u32 {
    let mut count = 0;
    let mut i = 0;
    while i < array.len() {
        if parse_id(*array.at(i)) == gear_type {
            count += 1;
        }
        i += 1;
    };
    count
}


pub fn contains_gear_type(array: Array<u256>, gear_type: GearType) -> bool {
    let mut found = false;
    let mut i = 0;

    while i < array.len() {
        if parse_id(*array.at(i)) == gear_type {
            found = true;
            // break early if found
            i = array.len(); // force exit loop
        } else {
            i += 1;
        }
    };

    found
}

