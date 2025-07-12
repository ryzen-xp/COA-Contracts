use starknet::ContractAddress;
use crate::helpers::base::ContractAddressDefault;
use core::num::traits::Zero;
use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use crate::erc1155::erc1155::{IERC1155MintableDispatcher, IERC1155MintableDispatcherTrait};
use crate::types::player::{PlayerRank, PlayerRankTrait};
use crate::types::base::{CREDITS};
use dojo::world::{WorldStorage};
use crate::models::gear::GearType;
use crate::helpers::gear::parse_id;

const DEFAULT_HP: u256 = 500;
const DEFAULT_MAX_EQUIPPABLE_SLOT: u32 = 10;
const WAIST_MAX_SLOTS: u32 = 8;
const HAND_MAX_COUNT: u32 = 2;
const MAX_SAME_TYPE_IN_WAIST: u32 = 2;
const FEET_MAX_SLOTS: u32 = 1;
const TORSO_MAX_SLOTS: u32 = 1;
const LEGS_MAX_SLOTS: u32 = 1;

#[derive(Drop, Clone, Serde, Debug, Default, Introspect)]
pub struct Body {
    pub head: u256, // For Helmet
    pub hands: Array<u256>, // For Gloves
    pub left_hand: Array<u256>,
    pub right_hand: Array<u256>,
    pub left_leg: Array<u256>,
    pub right_leg: Array<u256>,
    pub upper_torso: Array<u256>,
    pub lower_torso: Array<u256>,
    pub back: u256, // hangables, but it's usually just an item, leave it one for now.
    pub waist: Array<u256>, // Max 8 slots for now.
    pub feet: Array<u256>, // For Boots

    // Active non-body-worn gear
    // pub active_vehicle: u256,
}

#[dojo::model]
#[derive(Drop, Clone, Serde, Debug, Default)]
pub struct Player {
    #[key]
    pub id: ContractAddress,
    pub hp: u256,
    pub max_hp: u256,
    pub equipped: Array<u256>, // equipped from Player Inventory
    pub max_equip_slot: u32,
    pub rank: PlayerRank,
    pub level: u256, // this level is broken down from exps, usuable for boosters
    pub faction: felt252,
    pub next_rank_in: u64,
    pub body: Body, // body parts that can be equipped, like hands, legs, torso, etc.
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn init(ref self: Player, faction: felt252) {
        self.check();
        // does nothing if the player exists
        if self.max_hp == 0 {
            self.hp = DEFAULT_HP;
            self.max_hp = DEFAULT_HP;
            self.max_equip_slot = DEFAULT_MAX_EQUIPPABLE_SLOT;
            self.rank = Default::default();
            self.next_rank_in = self.rank.compute_max_val(); // change this
            self.body = Default::default(); 
        }
    }

    #[inline(always)]
    fn get_credits(ref self: Player, erc1155_address: ContractAddress) -> u256 {
        self.check();
        erc1155(erc1155_address).balance_of(self.id, CREDITS)
    }

    #[inline(always)]
    fn mint_credits(ref self: Player, amount: u256, erc1155_address: ContractAddress) {
        self.check();
        assert(amount > 0, 'INVALID AMOUNT');
        self.mint(CREDITS, erc1155_address, amount);
    }

    #[inline(always)]
    fn mint(ref self: Player, id: u256, erc1155_address: ContractAddress, amount: u256) {
        // to mint anything fungible
        // verify its id, and verify if it even exists
        // if fungible, use amount, else, ignore the amount.
        erc1155mint(erc1155_address).mint(self.id, id, amount, array![].span());
    }

    #[inline(always)]
    fn mint_batch(ref self: Player) {}

    #[inline(always)]
    fn purchase(
        ref self: Player, item_id: u256,
    ) { // use the item trait and add this to their inventory, using the erc1155
    // use the inventory trait `add to inventory` for this feat
    // the systems must check if this item exists before calling this function
    }

    fn is_available(self: @Player, item_id: u256) -> bool {
        true
    }

    fn use_item(
        ref self: Player, ref world: WorldStorage, id: u256,
    ) { // once used, it should be burned.
    // Say an asset that increases hp or xp.
    // All these should be done in the Inventory trait.
    // the item trait called by this function should take in the ref of this player
    // replace item_id with the original item to use it's trait
    // the world manipulations would be optimized here.
    // And i bet you can only use this item only if it is equipped.
    // Health should be fungible
    }

    fn add_xp(ref self: Player, value: u256) -> bool {
        // can be refactored to take in a task id with it's available xp to be earned or computed
        // for now it just takes in the raw value.
        // use the bool value to emit an event that a player has leveled up
        // or emit the event right from here.
        // and some combat skills mighht be locked until enough xp is gained.
        false
    }

    fn get_xp(self: @Player) -> u256 {
        // returns the player's xp.
        0
    }

    fn get_multiplier(self: @Player) -> u16 {
        // for the attack, the Rank level can serve as a multiplier.
        0
    }

    fn is_equippable(self: @Player, item_id: u256) -> bool {
        let gear_type = parse_id(item_id);
    
        match gear_type {
            GearType::Helmet => *self.body.head == 0_u256,
    
            GearType::ChestArmor => self.body.upper_torso.len() < TORSO_MAX_SLOTS,
            GearType::LegArmor => self.body.lower_torso.len() < LEGS_MAX_SLOTS,
            GearType::Boots => self.body.feet.len() < FEET_MAX_SLOTS,
            GearType::Gloves => self.body.hands.len() < HAND_MAX_COUNT,
    
            GearType::Shield => self.body.left_hand.len() < 1,

            // The back can hold Backpack, Quiver, Cape, etc.
            GearType::PetDrone => *self.body.back == 0_u256,
    
            GearType::BluntWeapon
            | GearType::Sword
            | GearType::Bow
            | GearType::Polearm
            | GearType::HeavyFirearms => {
                self.body.right_hand.len() < 1 || self.body.left_hand.len() < 1
            },
    
            GearType::Firearm => {
                let waist = self.body.waist;
                if waist.len() >= WAIST_MAX_SLOTS {
                    return false;
                }
    
                // count how many of same GearType exist in waist
                let mut count = 0;
                let mut i = 0;
                while i < waist.len() {
                    let item = *waist.at(i);
                    if parse_id(item) == gear_type {
                        count = count + 1;
                    }
                    i = i + 1;
                };
                count < MAX_SAME_TYPE_IN_WAIST
            },
    
            GearType::Weapon => {
                self.equipped.len() < *self.max_equip_slot
            },
    
            GearType::Vehicle => true, // yet to implement vehicle logic
            GearType::None => false,
        }
    }
    
    fn equip(ref self: Player, item_id: u256) {
        self.check();
        assert(item_id.is_non_zero(), Errors::INVALID_ITEM_ID);
        
        // check if the item is equippable
        assert(self.is_equippable(item_id), Errors::CANNOT_EQUIP);

        // check if the player has enough slots to equip this item
        assert(self.equipped.len() < self.max_equip_slot, Errors::INSUFFICIENT_SLOTS);

        let gear_type = parse_id(item_id);

        match gear_type {
            GearType::Helmet => self.body.head = item_id,
            GearType::Gloves => self.body.hands.append(item_id),
            GearType::Boots => self.body.feet.append(item_id),
            GearType::Shield => self.body.left_hand.append(item_id),
            GearType::BluntWeapon | GearType::Sword | GearType::Bow |
            GearType::Polearm | GearType::HeavyFirearms => {
                if self.body.right_hand.len() < 1 {
                    self.body.right_hand.append(item_id);
                } else {
                    self.body.left_hand.append(item_id);
                }
            },
            GearType::Firearm => {
                self.body.waist.append(item_id);
            },
            GearType::Weapon => {
                self.equipped.append(item_id);
            },

            // can Cape, Quiver, BackPack, etc.
            GearType::PetDrone => {
                self.body.back = item_id;
            },

            GearType::ChestArmor => self.body.upper_torso.append(item_id),
            GearType::LegArmor => self.body.lower_torso.append(item_id),
            GearType::Vehicle => {}, // Handle vehicle logic here
            _ => { // Do nothing
            },
        }

        self.equipped.append(item_id);
    }


    fn is_equipped(self: Player, type_id: u128) -> u256 {
        let equipped_arrays = array![
            self.equipped,
            self.body.right_hand,
            self.body.left_leg,
            self.body.right_leg,
            self.body.upper_torso,
            self.body.lower_torso,
            self.body.waist,
        ];

        let mut result: u256 = 0;
        let mut found = false;
        let mut i = 0;
        let arrays_len = equipped_arrays.len();
        while i < arrays_len && !found {
            let arr = equipped_arrays.at(i);
            let mut j = 0;
            let arr_len = arr.len();
            while j < arr_len && !found {
                let item = *arr.at(j);
                if get_high(item) == type_id {
                    result = item;
                    found = true;
                }
                j = j + 1;
            };
            i = i + 1;
        };

        if !found && get_high(self.body.back) == type_id {
            result = self.body.back;
        }

        result
    }

    #[inline(always)]
    fn check(self: @Player) {
        assert(self.id.is_non_zero(), Errors::ZERO_PLAYER);
    }
    // fn equip(ref self: Player, ref Item) {
//     assert()
// }
}

fn erc1155(contract_address: ContractAddress) -> IERC1155Dispatcher {
    IERC1155Dispatcher { contract_address }
}

fn erc1155mint(contract_address: ContractAddress) -> IERC1155MintableDispatcher {
    IERC1155MintableDispatcher { contract_address }
}

pub mod Errors {
    pub const ZERO_PLAYER: felt252 = 'ZERO PLAYER';
    pub const INVALID_ITEM_ID: felt252 = 'INVALID ITEM ID';
    pub const CANNOT_EQUIP: felt252 = 'CANNOT EQUIP';
    pub const INSUFFICIENT_SLOTS: felt252 = 'INSUFFICIENT EQUIP SLOTS';
}

// Helper function to get the high 128 bits from a u256
fn get_high(val: u256) -> u128 {
    val.high
}

fn get_low(val: u256) -> u128 {
    val.low
}
