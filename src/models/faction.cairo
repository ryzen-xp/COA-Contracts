use core::fmt::{Display, Formatter, Error};
use starknet::ContractAddress;
use dojo_starter::models::mission::{MissionStatus};
use dojo_starter::models::role::{Role};


#[derive(Drop, Serde)]
#[dojo::model]
pub struct Faction {
    #[key]
    pub id: u32,             
    pub name: ByteArray,        
    pub description: ByteArray,  
    pub players: Array<ContractAddress>,
    pub skills: Array<Skill>
}

#[derive(Serde, Drop, Introspect, Clone)]
pub struct Skill {           
    pub name: ByteArray,        
    pub effect: ByteArray,
}

#[generate_trait]
impl FactionImpl of FactionTrait {
    fn create_faction(
        id: u32,
        name: ByteArray,
        description: ByteArray,
        skills: Array<Skill>,
    ) -> Faction {
        Faction {
            id,
            name,
            description,
            skills,
            players: array![],
        }
    }
}

#[cfg(test)]
mod tests {
    use dojo_starter::models::mission::{MissionStatus};
    use dojo_starter::models::role::{Role};
    use dojo_starter::models::faction::{Faction, create_faction, Skill};
    use core::fmt::{Display, Formatter, Error};

    #[test]
    fn test_create_faction_function() {
        let id = 1_u32;
        let name = "Mercenaries";
        let description = "Mercenaries description";
        let skills = array![
                        Skill {name: "Rapid Attack", effect: "+20% base damage attack"}, 
                        Skill {name: "Elusive", effect: "+20% evade for 5 seconds"},
                    ];

        let faction = create_faction(
            id,
            name.clone(),
            description.clone(),
            skills.clone(),
        );

        assert_eq!(faction.id, id, "ID should match");
        assert_eq!(faction.name, name, "Name should match");
        assert_eq!(faction.description, description, "Description should match");
        assert_eq!(faction.players.len(), 0, "Players count should be 0");
        assert_eq!(faction.skills.len(), 2, "Skills count should be 2");
    }
}