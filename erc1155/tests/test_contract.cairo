use starknet::{ContractAddress, contract_address_const};
use erc1155::IERC1155::{ICitizenArcanisERC1155Dispatcher as IERC1155Dispatcher, ICitizenArcanisERC1155DispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use erc1155::utils::{
    CREDITS, CHEST_ARMOR, WEAPON_1,  HANDGUN_AMMO,  PET_1, 
};

fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn zero() -> ContractAddress {
    contract_address_const::<0>()
}

fn account1() -> ContractAddress {
    contract_address_const::<'kim'>()
}

fn account2() -> ContractAddress {
    contract_address_const::<'thurston'>()
}

fn account3() -> ContractAddress {
    contract_address_const::<'lee'>()
}

fn deploy() -> ContractAddress {
    let owner = owner();
    let base_uri: ByteArray = "ipfs://initial/";
    let contract = declare("CitizenArcanisERC1155").unwrap().contract_class();

    let mut calldata = array![];
    calldata.append_serde(owner);
    calldata.append_serde(base_uri);

    let (contract_address, deployment_result) = contract.deploy(@calldata).expect('Contract deployment failed');
    println!("Deployment result: {:?}", (contract_address, deployment_result));
    contract_address
}




#[test]
fn test_mint_nft_success() {
    let contract_address = deploy();
    let erc1155_dispatcher = IERC1155Dispatcher { contract_address };
    let recipient = account1();


    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));

    erc1155_dispatcher.mint_NFT(recipient, WEAPON_1);

    assert(erc1155_dispatcher.Balance_of(recipient, WEAPON_1) == 1, 'NFT_balance_mismatch');
    assert(erc1155_dispatcher.Balance_of(owner(), WEAPON_1) == 0, 'Owner_NFT_balance_nonzero');
}



