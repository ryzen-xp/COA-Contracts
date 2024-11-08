use starknet::ContractAddress;
use dojo_starter::{components::{mercenary::{Mercenary,MercenaryTrait},world::World,utils::{uuid, RandomTrait}}};
use dojo::model::{ModelStorage, ModelValueStorage};

#[generate_trait]
impl MercenaryWorldImpl of MercenaryWorldTrait {


    fn mint_mercenary(ref self: World, owner: ContractAddress) -> Mercenary {
        let id:u128 = 234;//uuid(self);
        let mut random = RandomTrait::new();
        let seed = random.next();
        let mercenary = MercenaryTrait::new(owner,id,seed);
        // let mut world = self.world(@"dojo_starter");
        self.write_model(@mercenary);
        mercenary
    }

    fn get_mercenary(ref self:World, id:u128) -> Mercenary {
        // let mut world = self.world(@"dojo_starter");
        let mercenary: Mercenary = self.read_model(id);
        assert(mercenary.owner.is_non_zero(), 'mercenary not exists');
        mercenary
    }


}