#[starknet::contract]
mod CitizenArcanisERC1155 {
    use openzeppelin::access::ownable::interface::IOwnable;
   use openzeppelin::token::erc1155::ERC1155Component::InternalTrait;
    use starknet::{ContractAddress,get_caller_address };
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess ,  };
    use core::num::traits::Zero; 
    use core::integer::u256;

    use openzeppelin::token::erc1155::{
        ERC1155Component, ERC1155HooksEmptyImpl, 
    };
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::ownable::{OwnableComponent, };

    // Constants
    // Using Felt252 for constants to avoid potential u256 issues in older Cairo versions if applicable
    // If using newer Cairo/Starknet, u256 is fine. Assuming u256 is okay here based on previous snippet.

    // Define Fungible Token IDs (Lower 128 bits)
    const CREDITS_ID: u256 = 1; // 0x1
    const HANDGUN_AMMO_ID: u256 = 256; // 0x100
    const MACHINE_GUN_AMMO_ID: u256 = 257; // 0x101
    // ... Add other FT IDs here following the 0x0 -> 0xFFF...FFF (lower 128 bits) range

    // Define NFT Category Prefixes (Upper 128 bits)
    // These are shifted left by 128 bits to occupy the upper part of the u256
    const WEAPONS_CATEGORY: u256 = u256::
    const HELMETS_CATEGORY: u256 = 8192_u256 << 128; // 0x2000 << 128
    const CHEST_ARMOR_CATEGORY: u256 = 8193_u256 << 128; // 0x2001 << 128
    const LEG_ARMOR_CATEGORY: u256 = 8194_u256 << 128; // 0x2002 << 128
    const BOOTS_CATEGORY: u256 = 8195_u256 << 128; // 0x2003 << 128
    const GLOVES_CATEGORY: u256 = 8196_u256 << 128; // 0x2004 << 128
    // Armor Range: 0x2000 - 0x2fff
    const VEHICLES_CATEGORY_START: u256 = 196608_u256 << 128; // 0x30000 << 128
    // Vehicles Range: 0x30000 - 0x3ffff
    const PETS_DRONES_CATEGORY_START: u256 = 8388608_u256 << 128; // 0x800000 << 128
    // Pets/Drones Range: 0x800000 - 0x8fffff



    // Define components
    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Embed ABIs / Implement internal traits
    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    // Use empty hooks for now, customize if needed (e.g., for robust supply=1 check)
    impl ERC1155HooksImpl = ERC1155HooksEmptyImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,        
        base_uri: ByteArray, 
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
     
        NFTMinted: NFTMinted,
        FTMinted: FTMinted,
    }

    #[derive(Drop, starknet::Event)]
    struct NFTMinted {
        minter: ContractAddress,
        recipient: ContractAddress,
        token_id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct FTMinted {
        minter: ContractAddress,
        recipient: ContractAddress,
        token_id: u256,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, base_uri_: ByteArray) {
        assert(!owner.is_zero(), 'Owner_zero_address');
        self.ownable.initializer(owner);
        self.erc1155.initializer(base_uri_); 
        
    }

    // --- Helper Functions ---

    /// Checks if a token ID follows the NFT format (upper 128 bits are non-zero).
   pub fn is_nft(token_id: u256) -> bool {
        (token_id >> 128) != 0
    }



    #[abi(embed_v0)]
    impl CitizenArcanisERC1155Impl of erc1155::IERC1155::ICitizenArcanisERC1155<ContractState> {
        // --- ERC1155 Views (Forwarded from Component) ---

        fn balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
            self.erc1155.balance_of(account, id)
        }

        fn balance_of_batch(
            self: @ContractState, accounts: Span<ContractAddress>, ids: Span<u256>
        ) -> Span<u256> {
            self.erc1155.balance_of_batch(accounts, ids)
        }

        fn is_approved_for_all(
            self: @ContractState, account: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc1155.is_approved_for_all(account, operator)
        }

 

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
          
            self.erc1155.set_approval_for_all(operator, approved);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            id: u256,
            amount: u256,
            data: Span<felt252>
        ) {
            
            self.erc1155.safe_transfer_from(from, to, id, amount, data);
        }

        fn safe_batch_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            ids: Span<u256>,
            amounts: Span<u256>,
            data: Span<felt252>
        ) {
            
            self.erc1155.safe_batch_transfer_from(from, to, ids, amounts, data);
        }



        /// @notice Mints multiple token types (FTs and NFTs) in a single transaction.
        /// @dev Only callable by the contract owner.
        /// @dev For NFTs, ensure the corresponding token_id in `ids` has a value of 1 in `values`.
        /// @dev For NFTs, ensure the token ID does not already exist to maintain supply=1.
        ///      The underlying _mint function should enforce this, but caller beware.
        /// @param account The address to mint tokens to.
        /// @param token_ids A span of token IDs to mint.
        /// @param values A span of amounts corresponding to each token ID.
        /// @param data Additional data (optional).
        fn batch_mint(
            ref self: ContractState,
            account: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>
        ) {
            self.ownable.assert_only_owner(); 
            assert(!account.is_zero(), 'account_zero_address');
            assert_eq!(token_ids.len(), values.len(), "IDs_and_values_length_mismatch");

            let mut i = 0;
            loop {
                if i == token_ids.len() { break; }
                let id = *token_ids.at(i);
                let value = *values.at(i);
                if is_nft(id) {
                    assert_eq!(value, 1_u256, "NFTs_must_have_value_1");               
                   
                }
                i += 1;
            };

             self.erc1155.batch_mint_with_acceptance_check(account , token_ids , values, data); 

             let mut i = 0;
             loop {
                 if i == token_ids.len() { break; }
                 let id = *token_ids.at(i);
                 let value = *values.at(i);
                 if is_nft(id) {
                     self.emit(NFTMinted { minter: get_caller_address(), recipient: account, token_id: id });
                 } else {
                     self.emit(FTMinted { minter: get_caller_address(), recipient: account, token_id: id, amount: value });
                 }
                 i += 1;
             };
        }


        fn mint_FT(ref self: ContractState, account: ContractAddress, token_id: u256, amount: u256) {
            self.ownable.assert_only_owner();
            assert(!is_nft(token_id), 'token_id_formate_of_NFT');
            assert(amount > 0, 'amount_must_>0');

            let ids = array![token_id].span();
            let values = array![amount].span();
            let data = array![].span();
            
            self.erc1155.batch_mint_with_acceptance_check(account , ids , values ,data );
            self.emit(FTMinted { minter: self.ownable.owner(), recipient: account, token_id, amount });
        }


        fn mint_NFT(ref self: ContractState, account: ContractAddress, token_id: u256) {
            self.ownable.assert_only_owner();
            assert(is_nft(token_id), 'Not_valid_NFT_id');
            assert(!account.is_zero(), 'account_zero_address');
            assert(self.erc1155.balance_of(account, token_id) == 0, 'account_already_owns_this_NFT');
     

            let ids = array![token_id].span();
            let values = array![1_u256].span(); 
            let data = array![].span();
           
            self.erc1155.batch_mint_with_acceptance_check(account , ids , values ,data );
            self.emit(NFTMinted { minter: self.ownable.owner(), recipient: account, token_id });
        }
       
        fn uri(self: @ContractState, token_id: u256) -> ByteArray {           
            self.base_uri.read()
        }
          
        fn set_base_uri(ref self: ContractState, new_base_uri: ByteArray) {
            self.ownable.assert_only_owner();
            self.base_uri.write(new_base_uri);
        }
    }
}