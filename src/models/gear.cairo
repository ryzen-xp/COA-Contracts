// This might be renamed to asset in the future
// For now we are sticking to gear, as some assets are not considered as gear
// These are all gears that are non-fungible

use crate::helpers::base::ContractAddressDefault;
use core::num::traits::Zero;
use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use crate::erc1155::erc1155::{IERC1155MintableDispatcher, IERC1155MintableDispatcherTrait};
use starknet::ContractAddress;
use dojo::world::WorldStorage;
use core::traits::{Into, TryInto};

#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct Gear {
    #[key]
    pub id: u256,
    pub item_type: felt252,
    pub asset_id: u256,
    // pub variation: // take in an instrospect enum, whether ammo, or companion, etc
    // I don't know if it's variation or not, but the type of that item.
    pub variation_ref: u256,
    pub total_count: u64, // for fungible.
    pub in_action: bool, // this translates to if this gear is ready to be used... just like a gun in hand, rather than a docked gun. This field would be used in important checks in the future.
    pub upgrade_level: u64,
    pub owner: ContractAddress, // owner field to track who owns the item 
    pub max_upgrade_level: u64,
    pub min_xp_needed: u256,
    pub spawned: bool,
}


#[derive(Drop, Copy, Serde, PartialEq, Default, Introspect)]
pub enum GearType {
    #[default]
    None,
    // General Weapon category prefix: 0x1
    Weapon, // 0x1
    // WeaponSubTypes -- 0x1xx
    BluntWeapon, // 0x101 - (e.g., Maces, hammers, clubs, axes)
    Sword, // 0x102 - (e.g., Katanas, greatswords, longswords, shortswords, daggers, knives)
    Bow, // 0x103 - (e.g., Compound bows, crossbows, longbows, shortbows)
    Firearm, // 0x104 - (e.g., Pistols, rifles, shotguns, SMGs (submachine guns))
    Polearm, // 0x105 - (e.g., Spears, lances, halberds, pikes, glaives)
    HeavyFirearms, // 0x106 (e.g., LMGs, Rocket Launchers, Grenade Launchers)
    Explosives, // 0x107 (e.g., Grenades, C4, Mines, Explosive Arrows)
    // ArmorTypes -- 0x2xxx
    Helmet, // 0x2000
    ChestArmor, // 0x2001
    LegArmor, // 0x2002
    Boots, // 0x2003
    Gloves, // 0x2004
    Shield, // 0x2005
    // VehicleTypes -- 0x3xxxx
    Vehicle, // 0x30000
    // Pets/Drones -- 0x8xxxxx
    Pet, // 0x800000
    Drone // 0x800001
}

#[derive(Drop, Copy, Serde, Default)]
pub struct GearProperties {
    asset_id: u256,
    // asset: Gear,
}

// This model stores the pre-calculated stats for each level of a specific asset.
#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct GearLevelStats {
    #[key]
    pub asset_id: u256, // The specific asset, e.g., Iron Sword
    #[key]
    pub level: u64, // The level for which these stats apply
    // --- Pre-calculated Stat Fields ---
    pub damage: u64,
    pub range: u64,
    pub accuracy: u64,
    pub fire_rate: u64,
    pub defense: u64,
    pub durability: u64,
    pub weight: u64,
}

// Struct to define a material required for an upgrade
#[derive(Drop, Copy, Serde, Introspect)]
pub struct UpgradeMaterial {
    pub token_id: u256,
    pub amount: u256,
}

// Model to store upgrade costs for each gear type and level
#[dojo::model]
#[derive(Drop, Serde)]
pub struct UpgradeCost {
    #[key]
    pub gear_type: GearType,
    #[key]
    pub level: u64,
    pub materials: Array<UpgradeMaterial>,
}

// Model to store success rates for each gear type and level
#[dojo::model]
#[derive(Drop, Serde)]
pub struct UpgradeSuccessRate {
    #[key]
    pub gear_type: GearType,
    #[key]
    pub level: u64,
    pub rate: u8,
}

// Model to track the state of the upgrade data initialization process.
#[dojo::model]
#[derive(Drop, Copy, Serde, Default)]
pub struct UpgradeConfigState {
    #[key]
    pub singleton_key: u8, // Always 0, to ensure only one instance exists.
    pub initialized_types_count: u32,
    pub is_complete: bool,
}

// for now, all items would implement this trait
// move this trait and it's impl to `helpers/gear.cairo`

#[generate_trait]
pub impl GearImpl of GearTrait {
    fn output(self: @Gear, upgraded_level: u64) -> u256 {
        // TODO: calculation for output based on upgraded level
        1000000
    }

    // pub trait GearTrait {
    //     fn with_id(id: u256) -> Gear;
    //     fn is_upgradeable(ref self: Gear) -> bool;
    //     fn forge(
    //         items: Array<u256>,
    //     ) -> u256; // can only be implemented on specific ids. Might invoke the worldstorage if
    //     necessary.
    //     fn is_fungible(id: u256);
    //     fn output(self: @Gear, value: u256);
    // }
    // ownership checking function
    fn is_owned(self: @Gear) -> bool {
        !self.owner.is_zero()
    }
    // function to check if available for pickup
    fn is_available_for_pickup(self: @Gear) -> bool {
        *self.spawned && self.owner.is_zero()
    }

    // Transfer ownership
    fn transfer_to(ref self: Gear, new_owner: ContractAddress) {
        self.owner = new_owner;
        self.spawned = false;
    }
}

// Implementation of conversion from GearType to felt252
impl GearTypeIntoFelt252 of Into<GearType, felt252> {
    fn into(self: GearType) -> felt252 {
        match self {
            GearType::None => 0x0,
            GearType::Weapon => 0x1,
            GearType::BluntWeapon => 0x101,
            GearType::Sword => 0x102,
            GearType::Bow => 0x103,
            GearType::Firearm => 0x104,
            GearType::Polearm => 0x105,
            GearType::HeavyFirearms => 0x106,
            GearType::Explosives => 0x107,
            GearType::Helmet => 0x2000,
            GearType::ChestArmor => 0x2001,
            GearType::LegArmor => 0x2002,
            GearType::Boots => 0x2003,
            GearType::Gloves => 0x2004,
            GearType::Shield => 0x2005,
            GearType::Vehicle => 0x30000,
            GearType::Pet => 0x800000,
            GearType::Drone => 0x800001,
        }
    }
}

// Implementation of conversion from felt252 to GearType
impl Felt252TryIntoGearType of TryInto<felt252, GearType> {
    fn try_into(self: felt252) -> Option<GearType> {
        if self == 0x1 {
            Option::Some(GearType::Weapon)
        } else if self == 0x101 {
            Option::Some(GearType::BluntWeapon)
        } else if self == 0x102 {
            Option::Some(GearType::Sword)
        } else if self == 0x103 {
            Option::Some(GearType::Bow)
        } else if self == 0x104 {
            Option::Some(GearType::Firearm)
        } else if self == 0x105 {
            Option::Some(GearType::Polearm)
        } else if self == 0x106 {
            Option::Some(GearType::HeavyFirearms)
        } else if self == 0x107 {
            Option::Some(GearType::Explosives)
        } else if self == 0x2000 {
            Option::Some(GearType::Helmet)
        } else if self == 0x2001 {
            Option::Some(GearType::ChestArmor)
        } else if self == 0x2002 {
            Option::Some(GearType::LegArmor)
        } else if self == 0x2003 {
            Option::Some(GearType::Boots)
        } else if self == 0x2004 {
            Option::Some(GearType::Gloves)
        } else if self == 0x2005 {
            Option::Some(GearType::Shield)
        } else if self == 0x30000 {
            Option::Some(GearType::Vehicle)
        } else if self == 0x800000 {
            Option::Some(GearType::Pet)
        } else if self == 0x800001 {
            Option::Some(GearType::Drone)
        } else {
            // If self is 0x0 or any other invalid code, return None.
            // Explicitly checking for 0x0 handles the default case.
            if self == 0x0 {
                Option::Some(GearType::None)
            } else {
                Option::None
            }
        }
    }
}
