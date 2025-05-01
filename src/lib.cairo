use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
#[dojo::model]
pub struct LeaderboardEntry {
    #[key]
    pub player_id: ContractAddress,
    pub kills: u32,
    pub deaths: u32,
}

pub trait LeaderboardSystem {
    fn kdr(self: @LeaderboardEntry) -> u32;
    fn is_valid(self: @LeaderboardEntry) -> bool;
}

pub impl LeaderboardImpl of LeaderboardSystem {
    fn kdr(self: @LeaderboardEntry) -> u32 {
        if *self.deaths == 0_u32 {
            1000_u32 
        } else {
            (*self.kills * 1000_u32) / *self.deaths
        }
    }

    fn is_valid(self: @LeaderboardEntry) -> bool {
        *self.kills <= 1000_u32 && *self.deaths <= 1000_u32
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use starknet::contract_address_const;

    #[test]
    fn test_kdr_normal_case() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x1>(),
            kills: 10_u32,
            deaths: 2_u32,
        };

        assert(entry.kdr() == 5000_u32, 1); 
        assert(entry.is_valid(), 2);        
    }

    #[test]
    fn test_kdr_zero_deaths() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x2>(),
            kills: 25_u32,
            deaths: 0_u32,
        };

        assert(entry.kdr() == 1000_u32, 3); 
    }

    #[test]
    fn test_kdr_large_ratio() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x3>(),
            kills: 100_u32,
            deaths: 1_u32,
        };

        assert(entry.kdr() == 100_000_u32, 4); 
    }

    #[test]
    fn test_invalid_kills() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x4>(),
            kills: 1001_u32,
            deaths: 10_u32,
        };

        assert(!entry.is_valid(), 5); 
    }

    #[test]
    fn test_invalid_deaths() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x5>(),
            kills: 100_u32,
            deaths: 1001_u32,
        };

        assert(!entry.is_valid(), 6); 
    }

    #[test]
    fn test_upper_bounds_valid() {
        let entry = LeaderboardEntry {
            player_id: contract_address_const::<0x6>(),
            kills: 1000_u32,
            deaths: 1000_u32,
        };

        assert(entry.is_valid(), 7); 
        assert(entry.kdr() == 1000_u32, 8); 
    }
}



