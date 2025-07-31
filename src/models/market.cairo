use starknet::ContractAddress;
use crate::helpers::base::ContractAddressDefault;

#[dojo::model]
#[derive(Drop, Serde, starknet::Store)]
pub struct Market_data {
    #[key]
    pub market_id: u256,
    pub owner: ContractAddress,
    pub is_auction: bool,
    pub is_active: bool,
    pub registration_timestamp: u64,
}

#[dojo::model]
#[derive(Drop, Serde, starknet::Store)]
pub struct MarketItem {
    #[key]
    pub item_id: u256,
    pub market_id: u256,
    pub owner: ContractAddress,
    pub price: u256,
    pub quantity: u256,
    pub is_available: bool,
    pub is_auction_item: bool,
}

#[dojo::model]
#[derive(Drop, Serde, starknet::Store)]
pub struct Auction {
    #[key]
    pub auction_id: u256,
    pub market_id: u256,
    pub item_id: u256,
    pub highest_bid: u256,
    pub highest_bidder: ContractAddress,
    pub end_time: u64,
    pub active: bool,
}
