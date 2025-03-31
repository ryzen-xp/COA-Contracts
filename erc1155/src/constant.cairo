// define fungible token ids lower 128 bits
const CREDITS_ID: u256 = 1; 
const HANDGUN_AMMO_ID: u256 = 256;
const MACHINE_GUN_AMMO_ID: u256 = 257; 


// define NFT Category Prefixes Upper 128 bits
const WEAPONS_CATEGORY: u256 = u256::
const HELMETS_CATEGORY: u256 = 8192_u256 << 128; 
const CHEST_ARMOR_CATEGORY: u256 = 8193_u256 << 128;
const LEG_ARMOR_CATEGORY: u256 = 8194_u256 << 128; 
const BOOTS_CATEGORY: u256 = 8195_u256 << 128; 
const GLOVES_CATEGORY: u256 = 8196_u256 << 128; 
// armor range: 0x2000 - 0x2fff
const VEHICLES_CATEGORY_START: u256 = 196608_u256 << 128; 
// vehicles range: 0x30000 - 0x3ffff
const PETS_DRONES_CATEGORY_START: u256 = 8388608_u256 << 128; 
// Pets/Drones range: 0x800000 - 0x8fffff

pub fn is_nft(token_id: u256) -> bool {
    true
}
