use crate::models::gear::GearType;

// Helper function to get the high 128 bits from a u256
fn get_high(val: u256) -> u128 {
    val.high
}

pub fn parse_id(id: u256) -> GearType {
    let category = get_high(id);

    // Match the high bits to determine the gear type
    if category == 0x1 {
        GearType::Weapon
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
        GearType::PetDrone
    } else {
        GearType::None // Fungible tokens or invalid
    }
}
