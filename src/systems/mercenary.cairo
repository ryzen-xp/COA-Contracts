use starknet::ContractAddress;
use dojo_starter::{components::{mercenary::{Mercenary,MercenaryTrait},world::World,utils::{uuid, RandomTrait}}};


#[generate_trait]
impl MercenaryWorldImpl of MercenaryWorldTrait {
    fn mint_mercenary(self:World,owner:ContractAddress) -> Mercenary {
        let id:u128 = uuid(self);
        let mut random = RandomTrait::new();
        let seed = random.next();
        let mercenary = MercenaryTrait::new(owner,id,seed);
        set!(self,(mercenary,));
        mercenary
    }

    fn get_mercenary(self:World, id:u128) -> Mercenary {
        let mercenary = get!(self,(id),Mercenary);
        assert(mercenary.owner.is_non_zero(), 'mercenary not exists');
        mercenary
    }


}