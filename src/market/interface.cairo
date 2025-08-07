use starknet::ContractAddress;
use coa::models::{gear::Gear, marketplace::{MarketData, MarketItem, Auction, Config}};

#[starknet::interface]
pub trait IMarketplace<TContractState> {
    // --- Admin Functions ---
    fn init(ref self: TContractState);
    fn set_admin(ref self: TContractState, new_admin: ContractAddress);
    fn update_config(
        ref self: TContractState,
        payment_token: ContractAddress,
        erc1155_address: ContractAddress,
        escrow_address: ContractAddress,
        registration_fee: u256,
    );
    fn withdraw_platform_fees(ref self: TContractState, to: ContractAddress, amount: u256);
    fn pause_marketplace(ref self: TContractState);
    fn unpause_marketplace(ref self: TContractState);

    // --- Market Management ---
    fn register_market(ref self: TContractState, is_auction: bool) -> u256;
    fn move_to_market(ref self: TContractState, item_ids: Array<u256>, prices: Array<u256>);
    fn add_to_market(ref self: TContractState, gear: Gear, price: u256, quantity: u256);
    fn remove_item_from_market(ref self: TContractState, item_id: u256);
    fn update_item_price(ref self: TContractState, item_id: u256, new_price: u256);
    fn bulk_update_prices(ref self: TContractState, item_ids: Array<u256>, new_prices: Array<u256>);
    fn bulk_remove_items(ref self: TContractState, item_ids: Array<u256>);

    // --- Trading Functions ---
    fn purchase_item(ref self: TContractState, item_id: u256, quantity: u256);
    fn start_auction(ref self: TContractState, item_id: u256, duration: u64, starting_bid: u256);
    fn place_bid(ref self: TContractState, auction_id: u256, amount: u256);
    fn end_auction(ref self: TContractState, auction_id: u256);

    // --- View Functions ---
    fn get_market_data(self: @TContractState, market_id: u256) -> MarketData;
    fn get_market_item(self: @TContractState, item_id: u256) -> MarketItem;
    fn get_auction(self: @TContractState, auction_id: u256) -> Auction;
    fn get_user_market(self: @TContractState, user: ContractAddress) -> u256;
    fn get_counters(self: @TContractState) -> (u256, u256, u256);
    fn get_config(self: @TContractState) -> Config;
}
