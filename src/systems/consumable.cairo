#[starknet::contract]
mod ConsumableSystem {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::contract_address::contract_address_const;
    use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        erc1155: IERC1155Dispatcher,
        local_inventory: LegacyMap<(ContractAddress, u256), u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ConsumableUsed: ConsumableUsed,
    }

    #[derive(Drop, starknet::Event)]
    struct ConsumableUsed {
        player_id: ContractAddress,
        token_id: u256,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, erc1155_address: ContractAddress) {
        self.erc1155.write(IERC1155Dispatcher { contract_address: erc1155_address });
    }

    #[external(v0)]
    fn use_consumable(ref self: ContractState, player_id: ContractAddress, token_id: u256, amount: u256) {
        assert(amount > 0, 'Amount must be greater than zero');
        assert(get_caller_address() == player_id, 'Only player can use consumables');
        let balance = self.erc1155.balance_of(player_id, token_id);
        assert(balance >= amount, 'Insufficient token balance');

        // Burn tokens by transferring to zero address
        self.erc1155.safe_transfer_from(player_id, contract_address_const::<0>(), token_id, amount, array![].span());

        // Update local inventory if tracked
        let current_inventory = self.local_inventory.read((player_id, token_id));
        if current_inventory >= amount {
            self.local_inventory.write((player_id, token_id), current_inventory - amount);
        }

        // Emit event
        self.emit(ConsumableUsed { player_id, token_id, amount });
    }

    #[external(v0)]
    fn update_inventory(ref self: ContractState, player_id: ContractAddress, token_id: u256, amount: u256) {
        // Add access control if needed
        self.local_inventory.write((player_id, token_id), amount);
    }
}