use starknet::ContractAddress;

/// REFACTOR THIS FILE
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct InventoryEntry {
    #[key]
    pub player_id: ContractAddress,
    pub token_id: felt252,
    pub quantity: u32,
}

pub trait InventorySystem {
    fn has_sufficient_quantity(self: @InventoryEntry, quantity: u32) -> bool;
    fn transfer_item(self: @InventoryEntry, receiver_id: ContractAddress, quantity: u32) -> bool;
}

pub impl InventoryImpl of InventorySystem {
    fn has_sufficient_quantity(self: @InventoryEntry, quantity: u32) -> bool {
        *self.quantity >= quantity
    }

    fn transfer_item(self: @InventoryEntry, receiver_id: ContractAddress, quantity: u32) -> bool {
        if !self.has_sufficient_quantity(quantity) {
            return false;
        }

        let mut sender_inventory = get_inventory_entry(*self.player_id, *self.token_id);
        sender_inventory.quantity -= quantity;
        // save_inventory_entry(sender_inventory);

        // let receiver_inventory = get_inventory_entry(receiver_id, self.token_id);
        // receiver_inventory.quantity += quantity;
        // save_inventory_entry(receiver_inventory);

        return true;
    }
}

fn get_inventory_entry(player_id: ContractAddress, token_id: felt252) -> InventoryEntry {
    let entry = fetch_inventory_from_storage(player_id, token_id);

    // for now
    // if entry.exists() {
    //     return entry;
    // } else {
    //     return InventoryEntry {
    //         player_id: player_id,
    //         token_id: token_id,
    //         quantity: 0_u32
    //     };
    // }
    entry
}

fn fetch_inventory_from_storage(player_id: ContractAddress, token_id: felt252) -> InventoryEntry {
    return InventoryEntry { player_id: player_id, token_id: token_id, quantity: 0_u32 };
}


#[cfg(test)]
mod tests {
    use super::*;
    use starknet::contract_address_const;

    #[test]
    fn test_transfer_item_valid() {
        let sender_id = contract_address_const::<0x1>();
        let receiver_id = contract_address_const::<0x2>();
        let token_id = 101;
        let quantity = 5_u32;

        let sender_entry = InventoryEntry {
            player_id: sender_id, token_id: token_id, quantity: 10_u32,
        };

        assert!(sender_entry.transfer_item(receiver_id, quantity), "Not equal");
    }

    #[test]
    fn test_transfer_item_insufficient_quantity() {
        let sender_id = contract_address_const::<0x1>();
        let receiver_id = contract_address_const::<0x2>();
        let token_id = 101;
        let quantity = 15_u32;

        let sender_entry = InventoryEntry {
            player_id: sender_id, token_id: token_id, quantity: 10_u32,
        };

        assert!(!sender_entry.transfer_item(receiver_id, quantity), "Not equal");
    }
}
