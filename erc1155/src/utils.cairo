// ────────────────────────────────────────────
// Fungible Tokens- Countable Assets
// ────────────────────────────────────────────

//  Currency
pub const CREDITS: u256 = u256 { low: 0x1, high: 0 };

// Ammo Types
pub const HANDGUN_AMMO: u256 = u256 { low: 0x100, high: 0 };
pub const MACHINE_GUN_AMMO: u256 = u256 { low: 0x101, high: 0 };

// ────────────────────────────────────────────
// Non-Fungible Tokens - Unique Assets
// ────────────────────────────────────────────

// Weapons
pub const WEAPON_1: u256 = u256 { low: 0x0001, high: 0x1 };
pub const WEAPON_2: u256 = u256 { low: 0x0002, high: 0x1 };

// Armor Types
pub const HELMET: u256 = u256 { low: 0x0001, high: 0x2000 };
pub const CHEST_ARMOR: u256 = u256 { low: 0x0001, high: 0x2001 };
pub const LEG_ARMOR: u256 = u256 { low: 0x0001, high: 0x2002 };
pub const BOOTS: u256 = u256 { low: 0x0001, high: 0x2003 };
pub const GLOVES: u256 = u256 { low: 0x0001, high: 0x2004 };

// Vehicles
pub const VEHICLE: u256 = u256 { low: 0x0001, high: 0x30000 };
pub const VEHICLE_2: u256 = u256 { low: 0x0002, high: 0x30000 };

// Pets / Drones
pub const PET_1: u256 = u256 { low: 0x0001, high: 0x800000 };
pub const PET_2: u256 = u256 { low: 0x0002, high: 0x800000 };


pub fn is_nft(token_id: u256) -> bool {
    token_id.high > 0 
}

pub fn is_FT(token_id : u256)-> bool {
    token_id.high ==0  && token_id.low > 0
}

