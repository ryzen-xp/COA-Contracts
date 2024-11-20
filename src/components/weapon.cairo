use dojo_starter::components::stats::{Stats,StatsTrait};

const WEAPON_COUNT:u8= 2;

#[derive(Copy, Drop, Serde, Introspect)]
enum Weapon {
    Sword,
    Katana
}

impl WeaponImpl of StatsTrait<Weapon>{
    fn stats(self: Weapon) ->Stats {
        match self {
            Weapon::Sword  => Stats { attack:4, defense:0, speed:3, strength:6},
            Weapon::Katana => Stats {attack:3, defense :0, speed :7, strength :2}
        }
    }
    fn index(self:Weapon) -> u8 {
        match self {
            Weapon::Sword => 0,
            Weapon::Katana => 1,
        }
    }
}

impl U8IntoWeapon of Into<u8, Weapon> {
    fn into(self: u8) -> Weapon{
        match self {
            0 => Weapon::Sword,
            1 => Weapon::Katana,
            _ => panic!("wrong weapon index")
        }
    }
}

impl WeaponIntoByteArray of Into<Weapon,ByteArray> {
    fn into(self:Weapon) ->ByteArray {
        match self {
            Weapon::Sword => "Sword",
            Weapon::Katana => "Katana"
        }
    }
}