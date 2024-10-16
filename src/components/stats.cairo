use core::option::OptionTrait;
use core::fmt::{Display, Formatter, Error};

#[derive(Copy,Drop,Serde,Introspect)]
pub struct Stats {
    attack:u16,
    defense:u16,
    speed:u16,
    strength:u16,
}

pub trait StatsTrait<T>{
    fn stats(self:T) -> Stats;
    fn index(self:T) -> u8;
}

impl DisplayImplT of Display<Stats> {
    fn fmt(self: @Stats, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "attack: {},\tdefense: {},\tspeed: {},\tstrength: {}",
            self.attack,
            self.defense,
            self.speed,
            self.strength
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

impl StatsAdd of Add<Stats> {
    fn add(lhs: Stats, rhs: Stats) -> Stats {
        return Stats {
            attack: lhs.attack + rhs.attack,
            defense: lhs.defense + rhs.defense,
            speed: lhs.speed + rhs.speed,
            strength: lhs.strength + rhs.strength,
        };
    }
}

impl StatsMul of Mul<Stats> {
    fn mul(lhs: Stats, rhs: Stats) -> Stats {
        return Stats {
            attack: lhs.attack * rhs.attack,
            defense: lhs.defense * rhs.defense,
            speed: lhs.speed * rhs.speed,
            strength: lhs.strength * rhs.strength,
        };
    }
}

impl StatsDiv of Div<Stats> {
    fn div(lhs: Stats, rhs: Stats) -> Stats {
        return Stats {
            attack: lhs.attack / rhs.attack,
            defense: lhs.defense / rhs.defense,
            speed: lhs.speed / rhs.speed,
            strength: lhs.strength / rhs.strength,
        };
    }
}

