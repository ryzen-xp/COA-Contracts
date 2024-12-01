#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo_starter::systems::faction::IFactionsWorldTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    use dojo_starter::{
        components::{
            mercenary::{Mercenary, m_Mercenary }, weapon::{Weapon}, stats::{Stats, StatsTrait}
        }
    };
    use dojo_starter::models::faction::{Faction, FactionImpl, Skill, m_Faction};
    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter", resources: [
                TestResource::Model(m_Faction::TEST_CLASS_HASH.try_into().unwrap()),
            ].span()
        };

        ndef
    }

    #[test]
    fn test_select_faction() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x07dc7899aa655b0aae51eadff6d801a58e97dd99cf4666ee59e704249e51adf2>();//test address
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        IFactionsWorldTrait::create_faction(ref world);

        IFactionsWorldTrait::select_faction(
            ref world, 1, caller
        );

        let updated_faction = IFactionsWorldTrait::get_faction(ref world, 1);

        assert_eq!(
            updated_faction.players.len(),
            1,
            "The amount of players should be 1"
        );

        assert_eq!(
            *updated_faction.players.at(0),
            caller,
            "The player should be the same caller"
        );
    }
}
