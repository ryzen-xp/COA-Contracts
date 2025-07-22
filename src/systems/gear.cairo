#[dojo::contract]
pub mod GearActions {
    use crate::interfaces::gear::IGear;
    use starknet::get_caller_address;
    use dojo::world::WorldStorage;
    use dojo::model::ModelStorage;
    use crate::models::gear::{Gear, GearProperties, GearType};
    use crate::models::core::Operator;
    use crate::helpers::base::generate_id;

    const GEAR: felt252 = 'GEAR';

    fn dojo_init(ref self: ContractState) {
        let mut world = self.world_default();
        self._assert_admin();
        self._initialize_gear_assets(ref world);
    }

    #[abi(embed_v0)]
    pub impl GearActionsImpl of IGear<ContractState> {
        fn upgrade_gear(
            ref self: ContractState, item_id: u256,
        ) { // check if the available upgrade materials `id` is present in the caller's address
        // TODO: Security
        // for now, you must check if if the item_id with id is available in the game.
        // This would be done accordingly, so the item struct must have the id of the material
        // or the ids of the list of materials that can upgrade it, and the quantity needed per
        // level and the max level attained.
        }

        fn equip(ref self: ContractState, item_id: Array<u256>) {}

        fn equip_on(ref self: ContractState, item_id: u256, target: u256) {}


        // unequips an item and equips another item at that slot.
        fn exchange(ref self: ContractState, in_item_id: u256, out_item_id: u256) {}

        fn refresh(
            ref self: ContractState,
        ) { // might be moved to player. when players transfer off contract, then there's a problem
        }

        fn get_item_details(ref self: ContractState, item_id: u256) -> Gear {
            // might not return a gear
            Default::default()
        }
        // Some Item Details struct.
        fn total_held_of(ref self: ContractState, gear_type: GearType) -> u256 {
            0
        }
        // use the caller and read the model of both the caller, and the target
        // the target only refers to one target type for now
        // This target type is raidable.
        fn raid(ref self: ContractState, target: u256) {}

        fn unequip(ref self: ContractState, item_id: Array<u256>) {}

        fn get_configuration(ref self: ContractState, item_id: u256) -> Option<GearProperties> {
            Option::None
        }

        // This configure should take in an enum that lists all Gear Types with their structs
        // This function would be blocked at the moment, we shall use the default configuration
        // of the gameplay and how items interact with each other.
        // e.g. guns auto-reload once the time has run out
        // and TODO: Add a delay for auto reload.
        // for a base gun, we default the auto reload to exactly 6 seconds...
        //
        fn configure(ref self: ContractState) { // params to be completed
        }

        fn auction(ref self: ContractState, item_ids: Array<u256>) {}
        fn dismantle(ref self: ContractState, item_ids: Array<u256>) {}
        fn transfer(ref self: ContractState, item_ids: Array<u256>) {}
        fn grant(ref self: ContractState, asset: GearType) {
            let mut world = self.world_default();
            self._assert_admin();

            // Create a new gear instance based on the asset type
            let new_gear_id = generate_id(GEAR, ref world);
            // Implementation would create gear based on asset type
        }

        // These functions might be reserved for players within a specific faction

        // this function forges and creates a new item id based
        fn forge(ref self: ContractState, item_ids: Array<u256>) {
            let mut world = self.world_default();
            // Create a new forged item with unique ID
            let forged_item_id = generate_id(GEAR, ref world);
            // Implementation would handle forging logic
        }

        fn awaken(ref self: ContractState, exchange: Array<u256>) {}

        fn can_be_awakened(self: @ContractState, item_ids: Array<u256>) -> Span<bool> {
            array![].span()
        }
    }

    #[generate_trait]
    pub impl GearInternalImpl of GearInternalTrait {
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"coa")
        }

        fn _assert_admin(self: @ContractState) { // assert the admin here.
            let world = self.world_default();
            let caller = get_caller_address();
            let operator: Operator = world.read_model(caller);
            assert(operator.is_operator, 'Caller is not admin');
        }

        fn _retrieve(
            ref self: ContractState, item_id: u256,
        ) { // this function should probably return an enum
        // or use an external function in the helper trait that returns an enum
        }

        fn _initialize_gear_assets(ref self: ContractState, ref world: WorldStorage) {
            // Weapons - using ERC1155 token IDs as primary keys
            let weapon_1_id = u256 { low: 0x0001, high: 0x1 };
            let weapon_1_gear = Gear {
                id: generate_id(GEAR, ref world), // WEAPON_1 from ERC1155
                item_type: 'WEAPON',
                asset_id: weapon_1_id, // u256.high for weapons
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 10,
            };
            world.write_model(@weapon_1_gear);

            // Weapon 1 stats
            let weapon_1_stats = crate::models::weapon_stats::WeaponStats {
                asset_id: weapon_1_id,
                damage: 45,
                range: 100,
                accuracy: 85,
                fire_rate: 15,
                ammo_capacity: 30,
                reload_time: 3,
            };
            world.write_model(@weapon_1_stats);

            let weapon_2_id = u256 { low: 0x0002, high: 0x1 };
            let weapon_2_gear = Gear {
                id: generate_id(GEAR, ref world), // WEAPON_2 from ERC1155
                item_type: 'WEAPON',
                asset_id: weapon_2_id,
                variation_ref: 2,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 10,
            };
            world.write_model(@weapon_2_gear);

            // Weapon 2 stats
            let weapon_2_stats = crate::models::weapon_stats::WeaponStats {
                asset_id: weapon_2_id,
                damage: 60,
                range: 80,
                accuracy: 90,
                fire_rate: 10,
                ammo_capacity: 20,
                reload_time: 4,
            };
            world.write_model(@weapon_2_stats);

            // Armor Types
            let helmet_id = u256 { low: 0x0001, high: 0x2000 };
            let helmet_gear = Gear {
                id: generate_id(GEAR, ref world), // HELMET from ERC1155
                item_type: 'ARMOR',
                asset_id: helmet_id, // u256.high for helmet
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 8,
            };
            world.write_model(@helmet_gear);

            // Helmet stats
            let helmet_stats = crate::models::armor_stats::ArmorStats {
                asset_id: helmet_id, defense: 25, durability: 100, weight: 2, slot_type: 'HELMET',
            };
            world.write_model(@helmet_stats);

            let chest_armor_id = u256 { low: 0x0001, high: 0x2001 };
            let chest_armor_gear = Gear {
                id: generate_id(GEAR, ref world), // CHEST_ARMOR from ERC1155
                item_type: 'ARMOR',
                asset_id: chest_armor_id, // u256.high for chest armor
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 8,
            };
            world.write_model(@chest_armor_gear);

            // Chest armor stats
            let chest_armor_stats = crate::models::armor_stats::ArmorStats {
                asset_id: chest_armor_id,
                defense: 50,
                durability: 150,
                weight: 8,
                slot_type: 'CHEST',
            };
            world.write_model(@chest_armor_stats);

            let leg_armor_id = u256 { low: 0x0001, high: 0x2002 };
            let leg_armor_gear = Gear {
                id: generate_id(GEAR, ref world), // LEG_ARMOR from ERC1155
                item_type: 'ARMOR',
                asset_id: leg_armor_id, // u256.high for leg armor
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 8,
            };
            world.write_model(@leg_armor_gear);

            // Leg armor stats
            let leg_armor_stats = crate::models::armor_stats::ArmorStats {
                asset_id: leg_armor_id, defense: 35, durability: 120, weight: 6, slot_type: 'LEGS',
            };
            world.write_model(@leg_armor_stats);

            let boots_id = u256 { low: 0x0001, high: 0x2003 };
            let boots_gear = Gear {
                id: generate_id(GEAR, ref world), // BOOTS from ERC1155
                item_type: 'ARMOR',
                asset_id: boots_id, // u256.high for boots
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 8,
            };
            world.write_model(@boots_gear);

            // Boots stats
            let boots_stats = crate::models::armor_stats::ArmorStats {
                asset_id: boots_id, defense: 20, durability: 80, weight: 3, slot_type: 'BOOTS',
            };
            world.write_model(@boots_stats);

            let gloves_id = u256 { low: 0x0001, high: 0x2004 };
            let gloves_gear = Gear {
                id: generate_id(GEAR, ref world), // GLOVES from ERC1155
                item_type: 'ARMOR',
                asset_id: gloves_id, // u256.high for gloves
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 8,
            };
            world.write_model(@gloves_gear);

            // Gloves stats
            let gloves_stats = crate::models::armor_stats::ArmorStats {
                asset_id: gloves_id, defense: 15, durability: 60, weight: 1, slot_type: 'GLOVES',
            };
            world.write_model(@gloves_stats);

            // Vehicles
            let vehicle_id = u256 { low: 0x0001, high: 0x30000 };
            let vehicle_gear = Gear {
                id: generate_id(GEAR, ref world), // VEHICLE from ERC1155
                item_type: 'VEHICLE',
                asset_id: vehicle_id, // u256.high for vehicles
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 5,
            };
            world.write_model(@vehicle_gear);

            // Vehicle 1 stats
            let vehicle_stats = crate::models::vehicle_stats::VehicleStats {
                asset_id: vehicle_id,
                speed: 80,
                armor: 60,
                fuel_capacity: 100,
                cargo_capacity: 500,
                maneuverability: 70,
            };
            world.write_model(@vehicle_stats);

            let vehicle_2_id = u256 { low: 0x0002, high: 0x30000 };
            let vehicle_2_gear = Gear {
                id: generate_id(GEAR, ref world), // VEHICLE_2 from ERC1155
                item_type: 'VEHICLE',
                asset_id: vehicle_2_id,
                variation_ref: 2,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 5,
            };
            world.write_model(@vehicle_2_gear);

            // Vehicle 2 stats (different variation)
            let vehicle_2_stats = crate::models::vehicle_stats::VehicleStats {
                asset_id: vehicle_2_id,
                speed: 60,
                armor: 90,
                fuel_capacity: 150,
                cargo_capacity: 800,
                maneuverability: 50,
            };
            world.write_model(@vehicle_2_stats);

            // Pets / Drones
            let pet_1_id = u256 { low: 0x0001, high: 0x800000 };
            let pet_1_gear = Gear {
                id: generate_id(GEAR, ref world), // PET_1 from ERC1155
                item_type: 'PET',
                asset_id: pet_1_id, // u256.high for pets
                variation_ref: 1,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 15,
            };
            world.write_model(@pet_1_gear);

            // Pet 1 stats
            let pet_1_stats = crate::models::pet_stats::PetStats {
                asset_id: pet_1_id,
                loyalty: 85,
                intelligence: 75,
                agility: 90,
                special_ability: 'STEALTH',
                energy: 100,
            };
            world.write_model(@pet_1_stats);

            let pet_2_id = u256 { low: 0x0002, high: 0x800000 };
            let pet_2_gear = Gear {
                id: generate_id(GEAR, ref world), // PET_2 from ERC1155
                item_type: 'PET',
                asset_id: pet_2_id,
                variation_ref: 2,
                total_count: 1,
                in_action: false,
                upgrade_level: 0,
                max_upgrade_level: 15,
            };
            world.write_model(@pet_2_gear);

            // Pet 2 stats
            let pet_2_stats = crate::models::pet_stats::PetStats {
                asset_id: pet_2_id,
                loyalty: 95,
                intelligence: 85,
                agility: 70,
                special_ability: 'COMBAT_SUPPORT',
                energy: 120,
            };
            world.write_model(@pet_2_stats);
        }
    }
}
