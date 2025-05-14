//********************************************************************
//                          IMPORTS                                 ||
//********************************************************************
use dojo::world::{WorldStorage, IWorldDispatcher, IWorldDispatcherTrait};
// mod models::player;
// mod systems::spawn_player;

// Alias `World` to `WorldStorage` for world state management.

type World = IWorldDispatcher;
type WorldE = WorldStorage;


fn do_something() {
    let storage = World { contract_address: 0.try_into().unwrap() };
}