use crate::models::gear::GearType;

// Helper function to get the high 128 bits from a u256
fn get_high(val: u256) -> u128 {
    val.high
}

pub fn parse_id(id: u256) -> GearType {
    let category = get_high(id);
    match category {
        0 => GearType::None, // Fungible tokens or invalid
        1 => GearType::Weapon,
        0x2000 => GearType::Helmet,
        0x2001 => GearType::ChestArmor,
        0x2002 => GearType::LegArmor,
        0x2003 => GearType::Boots,
        0x2004 => GearType::Gloves,
        _ => GearType::None,
        // Default::default()
    }
}

#[derive(Drop, Copy, Serde, PartialEq, Introspect)]
pub enum GearType {
    #[default]
    None,
    Weapon, // 0x1
    Helmet, // 0x2000
    ChestArmor, // 0x2001
    LegArmor, // 0x2002
    Boots, // 0x2003
    Gloves, // 0x2004
    // Add other types if needed, maybe they are equippable
}