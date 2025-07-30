use starknet::ContractAddress;
use coa::models::gear::Gear;

#[starknet::interface]
pub trait IMarketplace<TContractState> {
    fn register_market(ref self: TContractState, is_auction: bool) -> u256;
    fn move_to_market(ref self: TContractState, item_ids: Array<u256>);
    fn add_to_market(ref self: TContractState, gear: Gear);
    fn purchase_item(ref self: TContractState, item_id: u256, quantity: u256);
    fn start_auction(ref self: TContractState, item_id: u256, duration: u64, starting_bid: u256);
    fn place_bid(ref self: TContractState, auction_id: u256, amount: u256);
    fn end_auction(ref self: TContractState, auction_id: u256);
}

