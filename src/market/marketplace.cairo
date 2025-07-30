// @ryzen-xp
// NOTE:: If something meising ,I will Fix in future PRs !!
#[starknet::contract]
pub mod Marketplace {
    // THis is contract Imports !!
    use OwnableComponent::InternalTrait;
    use starknet::event::EventEmitter;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StorageMapReadAccess,
        StorageMapWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use coa::models::{gear::Gear, market::{Market_data, MarketItem, Auction}};
    use coa::market::interface::IMarketplace;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    use core::array::ArrayTrait;


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    // This is contract storage !!
    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        payment_token: ContractAddress, // this is token address for fees
        erc1155_address: ContractAddress, // this is erc1155 contract address !
        escrow_address: ContractAddress, // this is escrow address where all NFT and token is managed SOoo!!!
        market_counter: u256, // this counter count total market added !! 
        registation_fees: u256, //  this is fees for  new registration to market place
        registrations: Map<u256, Market_data>, // id--> Market_data !
        users_market: Map<
            ContractAddress, u256,
        >, //  user ==> market_id   ( by using user address we can fetch  attached market )
        item_counter: u256, // this counter  used to count item that listed in market to count 
        market_items: Map<u256, MarketItem>, //   market_id ==== > MarketItem  
        auction_counter: u256,
        auctions: Map<u256, Auction>,
    }

    // this is contract events !!
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Registration: Registration,
        GearAddedToMarket: GearAddedToMarket,
        ItemsMovedToMarket: ItemsMovedToMarket,
        ItemPurchased: ItemPurchased,
        AuctionStarted: AuctionStarted,
        BidPlaced: BidPlaced,
        AuctionEnded: AuctionEnded,
    }

    // THis is events  struct !!

    #[derive(Drop, starknet::Event)]
    pub struct Registration {
        pub id: u256,
        pub owner: ContractAddress,
        pub is_auction: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GearAddedToMarket {
        pub item_id: u256,
        pub market_id: u256,
        pub seller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ItemsMovedToMarket {
        pub market_id: u256,
        pub item_ids: Array<u256>,
        pub seller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ItemPurchased {
        pub buyer: ContractAddress,
        pub seller: ContractAddress,
        pub item_id: u256,
        pub quantity: u256,
        pub total_price: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AuctionStarted {
        pub auction_id: u256,
        pub item_id: u256,
        pub market_id: u256,
        pub end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BidPlaced {
        pub auction_id: u256,
        pub bidder: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AuctionEnded {
        pub auction_id: u256,
        pub winner: ContractAddress,
        pub final_bid: u256,
    }


    // This is contract Constractor !!
    #[constructor]
    fn constructor(
        ref self: ContractState,
        payment_token: ContractAddress,
        owner: ContractAddress,
        erc1155_address: ContractAddress,
        escrow: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.payment_token.write(payment_token);
        self.erc1155_address.write(erc1155_address);
        self.escrow_address.write(escrow);
    }

    #[abi(embed_v0)]
    pub impl MarketplaceImpl of IMarketplace<ContractState> {
        fn register_market(ref self: ContractState, is_auction: bool) -> u256 {
            let caller = get_caller_address();
            let mut old_counter = self.market_counter.read();
            let registration_fee = self.registation_fees.read();
            let payment_token = self.payment_token.read();
            let client = IERC20Dispatcher { contract_address: payment_token };

            assert(client.balance_of(caller) > registration_fee, 'Insufficent_Balance_caller');

            let new_counter = old_counter + 1;

            client.transfer_from(caller, get_contract_address(), registration_fee);

            let data = Market_data {
                market_id: new_counter,
                owner: caller,
                is_auction,
                is_active: true,
                registration_timestamp: get_block_timestamp(),
            };

            self.market_counter.write(new_counter);
            self.registrations.write(new_counter, data);
            self.users_market.write(caller, new_counter);

            self.emit(Registration { id: new_counter, owner: caller, is_auction });

            new_counter
        }
        // this is I think used to list  tthe item for sell  with
        fn move_to_market(ref self: ContractState, item_ids: Array<u256>) {
            let caller = get_caller_address();
            let market_id = self.users_market.read(caller);
            assert(market_id != 0, 'No_Market_Registered');

            let market = self.registrations.read(market_id);
            assert(market.owner == caller, 'Unauthorized_caller');
            assert(market.is_active, 'Market_Inactive');

            let client = IERC1155Dispatcher { contract_address: self.erc1155_address.read() };

            let mut ids: Array<u256> = array![];
            let mut amounts: Array<u256> = array![];

            let mut i = 0;
            loop {
                if i >= item_ids.len() {
                    break;
                }
                let id = *item_ids.at(i);

                if self._check_item_ownership(id, caller) {
                    ids.append(id);
                    amounts.append(1_u256);

                    // Create a new MarketItem entry for each NFT
                    let mut item_id = self.item_counter.read() + 1;
                    self.item_counter.write(item_id);

                    let market_item = MarketItem {
                        item_id,
                        market_id,
                        owner: caller,
                        price: 0_u256,
                        quantity: 1_u256,
                        is_available: true,
                        is_auction_item: market.is_auction,
                    };

                    self.market_items.write(item_id, market_item);
                }

                i += 1;
            };

            assert(ids.len() > 0, 'No_Valid_Items_To_Move');

            client
                .safe_batch_transfer_from(
                    caller,
                    self.escrow_address.read(),
                    ids.span(),
                    amounts.span(),
                    ArrayTrait::new().span(),
                );

            self.emit(ItemsMovedToMarket { market_id, item_ids: ids, seller: caller });
        }


        fn add_to_market(ref self: ContractState, gear: Gear) {
            self.ownable.assert_only_owner();
            // I don't understand this ?? , I will fix this in future PRs !!
        }

        fn purchase_item(ref self: ContractState, item_id: u256, quantity: u256) {
            let caller = get_caller_address();

            // Fetch the item
            let mut item = self.market_items.read(item_id);
            assert(item.is_available, 'Item_Not_Available');
            assert(quantity > 0, 'Invalid_Quantity');
            assert(item.quantity >= quantity, 'Not_Enough_Stock');

            let total_price = item.price * quantity;
            assert(total_price > 0, 'Invalid_Price');

            // Check buyer balance
            let token = self.payment_token.read();
            let client = IERC20Dispatcher { contract_address: token };
            assert(client.balance_of(caller) >= total_price, 'Insufficient_Balance');

            // Transfer payment from buyer to seller
            client.transfer_from(caller, item.owner, total_price);

            // Transfer NFT from escrow to buyer
            IERC1155Dispatcher { contract_address: self.erc1155_address.read() }
                .safe_transfer_from(
                    self.escrow_address.read(),
                    caller,
                    item.item_id,
                    quantity,
                    ArrayTrait::new().span(),
                );

            item.quantity -= quantity;
            if item.quantity == 0 {
                item.is_available = false;
            }

            self
                .emit(
                    ItemPurchased {
                        buyer: caller, seller: item.owner, item_id, quantity, total_price,
                    },
                );
            self.market_items.write(item_id, item);
        }


        fn start_auction(
            ref self: ContractState, item_id: u256, duration: u64, starting_bid: u256,
        ) {
            let caller = get_caller_address();

         
            let market_id = self.users_market.read(caller);
            assert(market_id != 0, 'No_Market_Registered');

            let market = self.registrations.read(market_id);
            assert(market.owner == caller, 'Unauthorized');
            assert(market.is_auction, 'Market_Not_Auction_Enabled');

    
            let item = self.market_items.read(item_id);
            assert(item.owner == caller, 'Not_Item_Owner');
            assert(item.is_available, 'Item_Not_Listed');

 
            let auction_id = self.auction_counter.read() + 1;
            self.auction_counter.write(auction_id);

            let new_auction = Auction {
                auction_id,
                market_id,
                item_id,
                highest_bid: starting_bid,
                highest_bidder: caller,
                end_time: get_block_timestamp() + duration,
                active: true,
            };
            self.auctions.write(auction_id, new_auction);

            self
                .emit(
                    AuctionStarted {
                        auction_id, item_id, market_id, end_time: get_block_timestamp() + duration,
                    },
                );
        }


        fn place_bid(ref self: ContractState, auction_id: u256, amount: u256) {
            let caller = get_caller_address();
            let mut auction = self.auctions.read(auction_id);

            assert(auction.active, 'Auction_Not_Active');
            assert(get_block_timestamp() < auction.end_time, 'Auction_Ended');
            assert(amount > auction.highest_bid, 'Bid_Too_Low');

            let token = self.payment_token.read();
            let client = IERC20Dispatcher { contract_address: token };
            assert(client.balance_of(caller) >= amount, 'Insufficient_Funds');

            // Refund previous highest bidder 
            if auction.highest_bidder != self.market_items.read(auction.market_id).owner {
                client.transfer(auction.highest_bidder, auction.highest_bid);
            }

            // Take new bid
            client.transfer_from(caller, get_contract_address(), amount);

            auction.highest_bid = amount;
            auction.highest_bidder = caller;
            self.auctions.write(auction_id, auction);

            self.emit(BidPlaced { auction_id, bidder: caller, amount });
        }

        fn end_auction(ref self: ContractState, auction_id: u256) {
            let mut auction = self.auctions.read(auction_id);

            assert(auction.active, 'Auction_Not_Active');
            assert(get_block_timestamp() >= auction.end_time, 'Auction_Not_Ended');

            auction.active = false;

            // Transfer payment to seller
            let item = self.market_items.read(auction.item_id);
            let client = IERC20Dispatcher { contract_address: self.payment_token.read() };
            client.transfer(item.owner, auction.highest_bid);

            // Transfer NFT to winner
            IERC1155Dispatcher { contract_address: self.erc1155_address.read() }
                .safe_transfer_from(
                    self.escrow_address.read(),
                    auction.highest_bidder,
                    auction.item_id,
                    1_u256,
                    ArrayTrait::new().span(),
                );

            self
                .emit(
                    AuctionEnded {
                        auction_id, winner: auction.highest_bidder, final_bid: auction.highest_bid,
                    },
                );

            self.auctions.write(auction_id, auction);
        }
    }

    #[generate_trait]
    impl InternalMarketplace of InternalMarketplaceTrait {
        //  In this function we check  owner have item > 0 so
        fn _check_item_ownership(
            ref self: ContractState, item: u256, owner: ContractAddress,
        ) -> bool {
            IERC1155Dispatcher { contract_address: self.erc1155_address.read() }
                .balance_of(owner, item) > 0
        }
    }
}
