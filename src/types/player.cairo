use alexandria_math::fast_power;

#[derive(Drop, Copy, Debug, Introspect, PartialEq, Serde, Default)]
pub struct Rank {
    #[default]
    value: PlayerRank,
    xp: u256,
}

/// For now, the player rank is hardcoded here
/// Can be upgraded in the future
#[derive(Drop, Copy, Debug, Introspect, PartialEq, Serde, Default)]
pub enum PlayerRank {
    #[default]
    F,
    E,
    D,
    C,
    B,
    A,
    S,
}

const BASE_XP: u256 = 1000; // can be changed.

#[generate_trait]
pub impl PlayerRankImpl of PlayerRankTrait {
    fn add_val(ref self: PlayerRank, val: u32) -> bool {
        let rank_changed = false;
        let mut xp: u128 = self.into();
    }

    #[inline(always)]
    fn compute_max_val(ref self: PlayerRank) -> u64 {// the value per rank increases exponentially
    }

    fn get_multiplier(ref self: PlayerRank) -> u32 {// should increase exponentially too.
        rank_xp_needed(@self);
    }
}

pub impl PlayerRankXP of Into<PlayerRank, u256> {
    #[inline(always)]
    fn into(self: PlayerRank) -> u256 {
        match self {
            PlayerRank::F => 0,
            PlayerRank::E => 1,
            PlayerRank::D => 2, 
            PlayerRank::C => 4,
            PlayerRank::B => 7,
            PlayerRank::A => 11,
            PlayerRank::S => 16,
        }
    }
}

fn rank_xp_needed(rank: @PlayerRank) -> u256 {
    let r: u256 = *rank.into();
    BASE_XP * fast_power((r + 3), 3).into()
}
