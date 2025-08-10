use starknet::ContractAddress;
pub const SECONDS_PER_DAY: u64 = 86400;

// Configuration model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Config {
    #[key]
    pub id: u8,
    pub next_market_id: u256,
    pub next_item_id: u256,
    pub next_auction_id: u256,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DailyCounter {
    #[key]
    pub user: ContractAddress,
    #[key]
    pub day: u256,
    pub counter: u256,
}

// Market data model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct MarketData {
    #[key]
    pub market_id: u256,
    pub owner: ContractAddress,
    pub is_auction: bool,
    pub is_active: bool,
    pub registration_timestamp: u64,
}

// Market item model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct MarketItem {
    #[key]
    pub item_id: u256,
    pub market_id: u256,
    pub token_id: u256,
    pub owner: ContractAddress,
    pub price: u256,
    pub quantity: u256,
    pub is_available: bool,
    pub is_auction_item: bool,
}

// Auction model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
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

// User market mapping
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct UserMarket {
    #[key]
    pub user: ContractAddress,
    pub market_id: u256,
}

// Error constants
pub mod Errors {
    pub const NOT_ADMIN: felt252 = 'Not admin';
    pub const ALREADY_INITIALIZED: felt252 = 'Already initialized';
    pub const INSUFFICIENT_BALANCE: felt252 = 'Insufficient balance';
    pub const NO_MARKET_REGISTERED: felt252 = 'No market registered';
    pub const UNAUTHORIZED_CALLER: felt252 = 'Unauthorized caller';
    pub const MARKET_INACTIVE: felt252 = 'Market inactive';
    pub const INVALID_PRICES_SIZE: felt252 = 'Invalid prices/items size';
    pub const NO_VALID_ITEMS: felt252 = 'No valid items to move';
    pub const ITEM_NOT_AVAILABLE: felt252 = 'Item not available';
    pub const INVALID_QUANTITY: felt252 = 'Invalid quantity';
    pub const NOT_ENOUGH_STOCK: felt252 = 'Not enough stock';
    pub const INVALID_PRICE: felt252 = 'Invalid price';
    pub const NOT_ITEM_OWNER: felt252 = 'Not item owner';
    pub const ITEM_NOT_LISTED: felt252 = 'Item not listed';
    pub const MARKET_NOT_AUCTION: felt252 = 'Market not auction enabled';
    pub const AUCTION_NOT_ACTIVE: felt252 = 'Auction not active';
    pub const AUCTION_ENDED: felt252 = 'Auction ended';
    pub const BID_TOO_LOW: felt252 = 'Bid too low';
    pub const INSUFFICIENT_FUNDS: felt252 = 'Insufficient funds';
    pub const AUCTION_NOT_ENDED: felt252 = 'Auction not ended';
    pub const ITEM_IS_AUCTION_ONLY: felt252 = 'Item is auction only';
    pub const ITEM_NOT_AUCTION_ITEM: felt252 = 'Item not auction item';
    pub const NOT_BUY_ITEM_OWNER_ALLOWED: felt252 = 'Item owner not_allow';
    pub const INVALID_GEAR_TYPE: felt252 = 'INVALID_GEAR_TYPE';
    pub const CONTRACT_PAUSED: felt252 = 'CONTRACT_PAUSED';
    pub const SELLER_CANNOT_BID: felt252 = 'SELLER_CANNOT_BID';
    pub const MARKET_ALREADY_REGISTERED: felt252 = 'MARKET_ALREADY_REGISTERED';
    pub const DAILY_LIMIT_EXCEEDED: felt252 = 'DAILY_LIMIT_EXCEEDED';
}

// Events
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct MarketRegistered {
    #[key]
    pub market_id: u256,
    #[key]
    pub owner: ContractAddress,
    pub is_auction: bool,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct ItemsMovedToMarket {
    #[key]
    pub market_id: u256,
    pub item_ids: Array<u256>,
    pub seller: ContractAddress,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct GearAddedToMarket {
    #[key]
    pub item_id: u256,
    pub market_id: u256,
    pub seller: ContractAddress,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct ItemPurchased {
    #[key]
    pub buyer: ContractAddress,
    #[key]
    pub seller: ContractAddress,
    #[key]
    pub item_id: u256,
    pub quantity: u256,
    pub total_price: u256,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct ItemPriceUpdated {
    #[key]
    pub item_id: u256,
    pub old_price: u256,
    pub new_price: u256,
    pub owner: ContractAddress,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct ConfigUpdated {
    #[key]
    pub payment_token: ContractAddress,
    pub erc1155_address: ContractAddress,
    pub escrow_address: ContractAddress,
    pub registration_fee: u256,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct PlatformFeesWithdrawn {
    #[key]
    pub to: ContractAddress,
    pub amount: u256,
    pub withdrawn_by: ContractAddress,
}


#[derive(Drop, Serde)]
#[dojo::event]
pub struct AuctionStarted {
    #[key]
    pub auction_id: u256,
    #[key]
    pub item_id: u256,
    pub market_id: u256,
    pub end_time: u64,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct BidPlaced {
    #[key]
    pub auction_id: u256,
    #[key]
    pub bidder: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct AuctionEnded {
    #[key]
    pub auction_id: u256,
    #[key]
    pub winner: ContractAddress,
    pub final_bid: u256,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct ItemRemovedFromMarket {
    #[key]
    pub item_id: u256,
    pub owner: ContractAddress,
}
