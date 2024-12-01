use starknet::{ContractAddress};
use dojo_starter::models::faction::{Faction, FactionTrait, Skill};
use dojo_starter::{
    components::{
        world::World, 
        utils::{uuid, RandomTrait},
    }
};
use dojo::model::{ModelStorage, ModelValueStorage};

#[generate_trait]
impl FactionsActionsImpl of IFactionsWorldTrait {
    fn create_faction(ref self: World) -> Faction {
        let id: u128 = 1;//uuid(self);
        let name = "Mercenaries";
        let description = "Mercenaries description";
        let skills = array![
                        Skill {name: "Rapid Attack", effect: "+20% base damage attack"}, 
                        Skill {name: "Elusive", effect: "+20% evade for 5 seconds"},
                    ];
        let faction = FactionTrait::create_faction(id,
            name.clone(),
            description.clone(),
            skills.clone());

        self.write_model(@faction);

        faction
    }

    fn select_faction(ref self: World, faction_id: u128, player: ContractAddress) {

        let mut faction: Faction = self.read_model(faction_id);
        faction.players.append(player);

        self.write_model(@faction);
    }

    fn get_faction(ref self: World, id: u128) -> Faction {

        let faction: Faction = self.read_model(id);
        faction
    }
}

