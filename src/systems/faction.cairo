use starknet::ContractAddress;
use dojo_starter::{
    components::{
        world::World, 
        utils::{uuid, RandomTrait},
    }
};

#[dojo::interface]
trait IFactionsActions {
    fn create_faction(ref self: World, owner: ContractAddress);
}

#[dojo::contract]
mod actions {
    use super::{IActions, next_position};
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::factions::{Faction, FactionImpl, Skill};
    use dojo_starter::{
        components::{
            world::World, 
            utils::{uuid, RandomTrait},
        }
    };

    #[abi(embed_v0)]
    impl FactionsActionsImpl of IFactionsActions<ContractState> {
        fn create_faction(ref self: World, owner: ContractAddress) {
            let id: u32 = 1;//uuid(self);
            let name = "Mercenaries";
            let description = "Mercenaries description";
            let skills = array![
                            Skill {name: "Rapid Attack", effect: "+20% base damage attack"}, 
                            Skill {name: "Elusive", effect: "+20% evade for 5 seconds"},
                        ];
            let faction = FactionImpl::create_faction(id,
                name.clone(),
                description.clone(),
                skills.clone());
    
            self.write_model(@faction);
        }
    
        // fn select_faction(ref self: World, faction_id: u128, /*player: ContractAddress*/) {
        //     // let mut world = self.world(@"dojo_starter");
        //     //Mercenary has two keys, id and owner, it must be read with both keys using a tuple
        //     let mercenary: Mercenary = self.read_model(faction_id);
        //     mercenary
        // }
    }
}
