use dojo_starter::components::stats::{Stats,StatsTrait};

const ARMOUR_COUNT:u8= 1;

#[derive(Copy, Drop, Serde, Introspect)]
enum Armour {
    Shield
}

impl ArmourImpl of StatsTrait<Armour> {
 fn stats(self:Armour) -> Stats {
    match self {
        Armour::Shield => Stats {attack:0, defense:6, speed:0, strength:6}
    }
 }
 
fn index(self:Armour) -> u8 {
    match self {
        Armour::Shield => 0
        }
    }
}

impl U8IntoArmour of Into<u8, Armour>{
    fn into(self:u8) -> Armour {
        match self {
            0 => Armour::Shield,
            _ => panic!("wrong armour index")
        }
    }
}

impl ArmourIntoByteArray of Into<Armour,ByteArray> {
    fn into(self:Armour) -> ByteArray{
        match self {
            Armour::Shield => "Shield"
        }
    }
}

