// This might be renamed to asset in the future
// For now we are sticking to gear, as some assets are not considered as gear
// These are all gears that are non-fungible

use crate::helpers::base::ContractAddressDefault;
use core::num::traits::Zero;
use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use crate::erc1155::erc1155::{IERC1155MintableDispatcher, IERC1155MintableDispatcherTrait};
use starknet::ContractAddress;
use dojo::world::WorldStorage;

#[dojo::model]
#[derive(Drop, Copy, Default, Serde)]
pub struct Gear {
    #[key]
    pub id: u256,
    pub item_type: felt252,
    pub asset_id: u256,
    // pub variation: // take in an instrospect enum, whether ammo, or companion, etc
    // I don't know if it's variation or not, but the type of that item.
    pub variation_ref: u256,
    pub total_count: u64, // for fungible.
    pub in_action: bool, // this translates to if this gear is ready to be used... just like a gun in hand, rather than a docked gun. This field would be used in important checks in the future.
    pub upgrade_level: u64,
    pub max_upgrade_level: u64,
}

#[derive(Drop, Copy, Serde, PartialEq, Default)]
pub enum GearType {
    #[default]
    None,
}

#[derive(Drop, Copy, Serde, Default)]
pub struct GearProperties {
    asset_id: u256,
    // asset: Gear,
}

// for now, all items would implement this trait
// move this trait and it's impl to `helpers/gear.cairo`

pub trait GearTrait {
    fn with_id(id: u256) -> Gear;
    fn is_upgradeable(ref self: Gear) -> bool;
    fn forge(
        items: Array<u256>,
    ) -> u256; // can only be implemented on specific ids. Might invoke the worldstorage if necessary.
    fn is_fungible(id: u256);
    fn get_output();
}
