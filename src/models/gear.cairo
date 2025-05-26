// This might be renamed to asset in the future
// For now we are sticking to gear, as some assets are not considered as gear
// These are all gears that are non-fungible

use crate::helpers::base::ContractAddressDefault;
use core::num::traits::Zero;
use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use crate::erc1155::erc1155::{IERC1155MintableDispatcher, IERC1155MintableDispatcherTrait};
use starknet::ContractAddress;

#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub mod Gear {
    #[key]
    pub id: (u256, ContractAddress),    // the u256 here is the 
    pub item_type: felt252,
    pub variation: // take in an instrospect enum, whether ammo, or companion, etc
    // I don't know if it's variation or not, but the type of that item.
    pub variation_ref: u256,
    pub total_count: u64,   // for checks
    pub total_held: u64,    // for stats
    pub in_action: bool,    // this translates to if this gear is ready to be used... just like a gun in hand, rather than a docked gun. This field would be used in important checks in the future.
}

// for now, all items would implement this trait
// move this trait and it's impl to `helpers/gear.cairo` 

pub trait GearTrait {
    fn with_id(id: u256) -> Gear;
    fn is_upgradeable(ref self: Gear) -> {

    }

    fn forge() -> u256 {

    }
}