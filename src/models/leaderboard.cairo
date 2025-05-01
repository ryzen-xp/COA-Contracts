use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct LeaderboardEntry {
    #[key]
    pub player_id: ContractAddress,
    pub kills: u32,
    pub deaths: u32,
}
