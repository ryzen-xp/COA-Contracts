use crate::models::player::Player;

#[starknet::interface]
pub trait IPlayer<TContractState> {
    fn new(ref self: TContractState, faction: felt252);
    fn deal_damage(
        ref self: TContractState,
        attacker_id: u256,
        target: Array<u256>,
        target_types: Array<felt252>,
        with_items: Array<u256>,
    );
    fn get_player(self: @TContractState, player_id: u256) -> Player;
    fn register_guild(ref self: TContractState);
    fn transfer_objects(
        ref self: TContractState, object_ids: Array<u256>, to: starknet::ContractAddress,
    );
    fn refresh(ref self: TContractState, player_id: u256);
}

#[dojo::contract]
pub mod PlayerActions {
    use starknet::{ContractAddress, get_caller_address};
    use crate::models::player::{Player, PlayerTrait};
    use crate::erc1155::erc1155::{
        IERC1155Dispatcher, IERC1155DispatcherTrait, IERC1155MintableDispatcher,
        IERC1155MintableDispatcherTrait,
    };
    use super::IPlayer;

    // const GEAR_
    const MIN_THRESHOLD: u32 = 80;


    fn dojo_init(
        ref self: ContractState, admin: ContractAddress, default_amount_of_credits: u256,
    ) { // write admin
    // write default amount of credits.

    }

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayer<ContractState> {
        fn new(ref self: ContractState, faction: felt252) { // create the player
        // and call mint
        // maybe in the future, you implement a `mint_default()`
        // spawn player at some random location.
        }

        fn deal_damage(
            ref self: ContractState,
            attacker_id: u256,
            target: Array<u256>,
            target_types: Array<felt252>,
            with_items: Array<u256>,
        ) {
            let attacker = self.get_player(attacker_id);
            let attacker_xp: u32 = attacker.xp;

            for i in 0..target.len() {
                let target_id = target.at(i);
                let target_player = self.get_player(*target_id);
                let target_xp: u32 = target_player.xp;

                let xp_diff = if attacker_xp >= target_xp {
                    attacker_xp - target_xp
                } else {
                    target_xp - attacker_xp
                };

                let mut multiplier = (xp_diff / MIN_THRESHOLD) + 1;
                if multiplier < 1 {
                    multiplier = 1;
                }

                //  For now base damage is hardcoded,It dynamicly depandenton  iteam/ weapon type
                let base_damage: u32 = 10;

                let actual_damage = if attacker_xp >= target_xp {
                    base_damage * multiplier
                } else {
                    base_damage / multiplier
                };

                self.receive_damage(*target_id, actual_damage.into());
            }
            // assert that the items are something that can deal damage
        // from no. 2, not just assert, handle appropriately, but do not panic
        // factor in the faction type and add additional damage
        // factor in the weapon type and xp // rank trait.
        // and factor in the item type, if the item has been upgraded
        // check if the item has been equipped
        // to find out the item's output when upgraded, call the item.output(val), where val is
        // the upgraded level.

            // if with_items.len() is zero, then it's a normal melee attack.

            // factor in the target's damage factor... might later turn out not to be damaged
        // this means that each target or item should have a damage factor, and might cause
        // credits to be repaired

            // for the target, the above is if the target_type is an object.
        // if the target type is a living organism, check all the eqippable traits
        // this means that the PlayerTrait should have a recieve_damage,

            // or recieve damage should probably be an internal trait for now.
        }

        fn get_player(self: @ContractState, player_id: u256) -> Player {
            Default::default()
        }

        fn register_guild(ref self: ContractState) {}

        fn transfer_objects(ref self: ContractState, object_ids: Array<u256>, to: ContractAddress) {
            // Get the caller's address (current owner of the objects)
            let caller = get_caller_address();

            // Get the ERC1155 contract address from the system
            let erc1155_address = self.get_erc1155_address();

            // Transfer each object to the destination address
            let mut i = 0;
            let len = object_ids.len();
            while i < len {
                let object_id = *object_ids.at(i);
                // Transfer the object (with amount 1 for NFTs)
                let erc1155_dispatcher = erc1155(erc1155_address);
                erc1155_dispatcher.safe_transfer_from(caller, to, object_id, 1, array![].span());
                i += 1;
            }
        }

        fn refresh(ref self: ContractState, player_id: u256) {
            // Get the player's address
            let player = self.get_player(player_id);
            let player_address = player.id;

            // Get the ERC1155 contract address
            let erc1155_address = self.get_erc1155_address();

            // Get the list of game object IDs that we need to check
            let game_object_ids = self.get_game_object_ids();

            // Create an ERC1155 dispatcher to interact with the contract
            let erc1155_dispatcher = erc1155(erc1155_address);

            // Check each game object to see if the player has it
            let mut i = 0;
            let len = game_object_ids.len();

            while i < len {
                let object_id = *game_object_ids.at(i);

                // Get the player's balance of this object from the ERC1155 contract
                let balance = erc1155_dispatcher.balance_of(player_address, object_id);

                // If the player has this object in their wallet but not in the game state,
                // update the game state to reflect this
                if balance > 0 {
                    // Check if the object is already registered in the player's inventory
                    let is_registered = self.is_object_registered(player_id, object_id);

                    if !is_registered {
                        // Register the object in the player's inventory
                        self.register_object(player_id, object_id, balance);
                    } else {
                        // Update the object quantity if it has changed
                        self.update_object_quantity(player_id, object_id, balance);
                    }
                }

                i += 1;
            };

            // Emit an event indicating the refresh was completed
            self.emit_refresh_event(player_id);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn receive_damage(ref self: ContractState, player_id: u256, damage: u256) {}

        fn get_erc1155_address(self: @ContractState) -> ContractAddress {
            // In a real implementation, this would be stored in the contract state
            // For now, we return a placeholder address
            // This should be replaced with the actual ERC1155 contract address
            starknet::contract_address_const::<0x0>()
        }

        fn emit_refresh_event(
            ref self: ContractState, player_id: u256,
        ) { // In a real implementation, this would emit an event
        // For now, this is just a placeholder
        }

        fn get_game_object_ids(self: @ContractState) -> Array<u256> {
            // In a real implementation, this would return a list of all game object IDs
            // that can be owned by players
            // For now, we return an empty array
            array![]
        }

        fn is_object_registered(self: @ContractState, player_id: u256, object_id: u256) -> bool {
            // In a real implementation, this would check if the object is already registered
            // in the player's inventory in the game state
            // For now, we return false
            false
        }

        fn register_object(
            ref self: ContractState, player_id: u256, object_id: u256, quantity: u256,
        ) {
            // In a real implementation, this would register the object in the player's inventory
            // in the game state
            // For now, this is just a placeholder

            // Get the player model
            let mut player = self.get_player(player_id);
            // Depending on the object type, we would add it to the appropriate inventory slot
        // This is a simplified implementation

            // For example, if it's an equippable item, we might add it to the player's equipped
        // array player.equipped.append(object_id);

            // Then we would update the player model in the world state
        // set_player(player_id, player);
        }

        fn update_object_quantity(
            ref self: ContractState, player_id: u256, object_id: u256, quantity: u256,
        ) { // In a real implementation, this would update the quantity of the object
        // in the player's inventory in the game state
        // For now, this is just a placeholder
        }
    }

    fn erc1155(contract_address: ContractAddress) -> IERC1155Dispatcher {
        IERC1155Dispatcher { contract_address }
    }
}
