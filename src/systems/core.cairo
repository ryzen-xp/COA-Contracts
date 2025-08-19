/// interface
/// init an admin account, or list of admin accounts, dojo_init
///
/// Spawn tournamemnts and side quests here, if necessary.

use coa::models::gear::Gear;
#[starknet::interface]
pub trait ICore<TContractState> {
    fn spawn_items(ref self: TContractState, amount: u256);
    // move to market only items that have been spawned.
    // if caller is admin, check spawned items and relocate
    // if caller is player,
    fn move_to_market(ref self: TContractState, item_ids: Array<u256>);
    fn add_to_market(ref self: TContractState, item_ids: Array<u256>);
    // can be credits, materials, anything
    fn purchase_item(ref self: TContractState, item_id: u256, quantity: u256);
    fn create_tournament(ref self: TContractState);
    fn join_tournament(ref self: TContractState);
    fn purchase_credits(ref self: TContractState);
    fn random_gear_generator(ref self: TContractState) -> Gear;
    fn pick_items(ref self: TContractState, item_ids: Array<u256>) -> Array<u256>;
}

#[dojo::contract]
pub mod CoreActions {
    use super::super::super::erc1155::erc1155::IERC1155MintableDispatcherTrait;
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::ModelStorage;
    use crate::models::core::{Contract, Operator, GearSpawned, ItemPicked};
    use crate::models::gear::*;
    use crate::systems::gear::GearActions::GearActionsImpl;
    use core::array::ArrayTrait;
    use crate::erc1155::erc1155::IERC1155MintableDispatcher;
    use dojo::event::{EventStorage};
    use coa::systems::gear::*;
    use dojo::world::WorldStorage;
    use coa::helpers::gear::*;
    use coa::models::player::*;
    use core::num::traits::Zero;
    use core::traits::Into;

    const GEAR: felt252 = 'GEAR';
    const COA_CONTRACTS: felt252 = 'COA_CONTRACTS';

    fn dojo_init(
        ref self: ContractState,
        admin: ContractAddress,
        erc1155: ContractAddress,
        payment_token: ContractAddress,
        escrow_address: ContractAddress,
        registration_fee: u256,
        warehouse: ContractAddress,
    ) {
        let mut world = self.world(@"coa_contracts");

        // Initialize admin
        let operator = Operator { id: admin, is_operator: true };
        world.write_model(@operator);

        // Initialize contract configuration
        let contract = Contract {
            id: COA_CONTRACTS,
            admin,
            erc1155,
            payment_token,
            escrow_address,
            registration_fee,
            paused: false,
            warehouse,
        };
        world.write_model(@contract);
    }

    #[abi(embed_v0)]
    pub impl CoreActionsImpl of super::ICore<ContractState> {
        //@ryzen-xp
        fn spawn_items(ref self: ContractState, mut amount: u256) {
            let caller = get_caller_address();
            let mut world = self.world_default();
            let contract: Contract = world.read_model(COA_CONTRACTS);
            assert(caller == contract.admin, 'Only admin can spawn items');

            let erc1155_dispatcher = IERC1155MintableDispatcher {
                contract_address: contract.erc1155,
            };

            let mut items = array![];

            while amount != 0 {
                let mut gear: Gear = self.random_gear_generator();

                assert(!gear.spawned, 'Gear already spawned');
                gear.spawned = true;
                world.write_model(@gear);
                items.append(gear.id);
                amount -= 1;

                erc1155_dispatcher.mint(contract.warehouse, gear.id, 1, array![].span());
            };
            let event = GearSpawned { admin: caller, items };
            world.emit_event(@event);
        }
        // move to market only items that have been spawned.
        // if caller is admin, check spawned items and relocate
        // if caller is player,
        fn move_to_market(ref self: ContractState, item_ids: Array<u256>) {}
        fn add_to_market(ref self: ContractState, item_ids: Array<u256>) {}
        // can be credits, materials, anything
        fn purchase_item(ref self: ContractState, item_id: u256, quantity: u256) {}
        fn create_tournament(ref self: ContractState) {}
        fn join_tournament(ref self: ContractState) {}
        fn purchase_credits(ref self: ContractState) {}

        //@ryzen-xp
        // random gear  item genrator
        fn random_gear_generator(ref self: ContractState) -> Gear {
            let caller = get_caller_address();
            let mut world = self.world_default();
            let contract: Contract = world.read_model(COA_CONTRACTS);
            assert(caller == contract.admin, 'Only admin can spawn items');

            let gear_type = random_geartype();
            let item_type: felt252 = gear_type.into();
            let item_id: u256 = self.generate_incremental_ids(gear_type.into());
            let max_upgrade_level: u64 = get_max_upgrade_level(gear_type);
            let min_xp_needed: u256 = get_min_xp_needed(gear_type);

            let gear = Gear {
                id: item_id,
                item_type,
                asset_id: item_id.low.into(),
                variation_ref: 0,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                owner: caller,
                max_upgrade_level,
                min_xp_needed,
                spawned: true,
            };

            world.write_model(@gear);
            gear
        }

        //@ryzen-xp
        fn pick_items(ref self: ContractState, item_ids: Array<u256>) -> Array<u256> {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let contract: Contract = world.read_model(COA_CONTRACTS);
            let mut player: Player = world.read_model(caller);

            // Initialize player
            player.init('default');

            let mut successfully_picked: Array<u256> = array![];

            let has_vehicle = player.has_vehicle_equipped();

            let mut i = 0;
            while i < item_ids.len() {
                let item_id = *item_ids.at(i);
                let mut gear: Gear = world.read_model(item_id);

                assert(gear.is_available_for_pickup(), 'Item not available');

                // Check if player meets XP requirement
                if player.xp < gear.min_xp_needed {
                    i += 1;
                    continue;
                }

                let mut equipped = false;
                let mut mint_item = false;

                if has_vehicle {
                    // If player has vehicle, mint all items directly to inventory
                    mint_item = true;
                } else {
                    if player.is_equippable(item_id) {
                        PlayerTrait::equip(ref player, item_id);
                        equipped = true;
                        mint_item = true;
                    } else {
                        if player.has_free_inventory_slot() {
                            mint_item = true;
                        }
                    }
                }

                if mint_item {
                    // Mint the item to player's inventory
                    player.mint(item_id, contract.erc1155, 1);

                    // Update gear ownership and spawned state
                    gear.transfer_to(caller);
                    world.write_model(@gear);

                    // Add to successfully picked array
                    successfully_picked.append(item_id);

                    // Emit itempicked event
                    world
                        .emit_event(
                            @ItemPicked {
                                player_id: caller,
                                item_id: item_id,
                                equipped: equipped,
                                via_vehicle: has_vehicle,
                            },
                        );
                }

                i += 1;
            };

            // Update Player state
            world.write_model(@player);

            successfully_picked
        }
    }

    #[generate_trait]
    pub impl CoreInternalImpl of CoreInternalTrait {
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"coa")
        }

        //@ryzen-xp
        // Generates an incremental u256 ID based on gear_id.high.
        fn generate_incremental_ids(ref self: ContractState, item_id: u256) -> u256 {
            let mut world = self.world_default();

            let mut gear_counter: GearCounter = world.read_model(item_id.high);

            let data = GearCounter { id: item_id.high, counter: gear_counter.counter + 1 };

            world.write_model(@data);

            let id = u256 { high: data.id, low: data.counter };
            id
        }
    }
}
