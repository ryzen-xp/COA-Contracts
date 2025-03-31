use starknet::ContractAddress;
use core::byte_array::ByteArray; // Import ByteArray for the uri function

#[starknet::interface]
pub trait ICitizenArcanisERC1155<TContractState> {
    // --- Standard ERC1155 View Functions ---

    /// @notice Get the balance of an account's tokens.
    /// @param account The address of the token holder.
    /// @param id ID of the token.
    /// @return The account's balance of the token type.
    fn balance_of(self: @TContractState, account: ContractAddress, id: u256) -> u256;

    /// @notice Get the balance of multiple account/token pairs.
    /// @param accounts The addresses of the token holders.
    /// @param ids IDs of the tokens.
    /// @return The accounts' balances of the token types (order correlated to inputs).
    fn balance_of_batch(
        self: @TContractState, accounts: Span<ContractAddress>, ids: Span<u256>
    ) -> Span<u256>;

    /// @notice Query if an address is an authorized operator for another address.
    /// @param account The address that owns the tokens.
    /// @param operator The address that acts on behalf of the account.
    /// @return True if the operator is approved, false otherwise.
    fn is_approved_for_all(
        self: @TContractState, account: ContractAddress, operator: ContractAddress
    ) -> bool;

    // --- Standard ERC1155 Transfer/Approval Functions ---

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator Address to add to the set of authorized operators.
    /// @param approved True if the operator is approved, false to revoke approval.
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);

    /// @notice Transfer tokens from one address to another.
    /// @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// @dev MUST emit TransferSingle event on success.
    /// @param from Source address.
    /// @param to Target address.
    /// @param id ID of the token type.
    /// @param amount Amount of tokens to transfer.
    /// @param data Additional data with no specified format.
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        amount: u256,
        data: Span<felt252>
    );

    /// @notice Transfer multiple types of tokens from one address to another.
    /// @dev Caller must be approved to manage all the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// @dev MUST emit one or more TransferBatch events on success.
    /// @param from Source address.
    /// @param to Target address.
    /// @param ids IDs of each token type (order and length must match `amounts`).
    /// @param amounts Amount of each token type (order and length must match `ids`).
    /// @param data Additional data with no specified format.
    fn safe_batch_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        ids: Span<u256>,
        amounts: Span<u256>,
        data: Span<felt252>
    );

    // --- Custom Minting Functions (Owner Restricted in Implementation) ---

    /// @notice Mints multiple token types (FTs and NFTs) in a single transaction.
    /// @dev Restricted to contract owner in the implementation.
    /// @param account The address to mint tokens to.
    /// @param token_ids A span of token IDs to mint.
    /// @param values A span of amounts corresponding to each token ID.
    /// @param data Additional data (optional).
    fn batch_mint(
        ref self: TContractState,
        account: ContractAddress,
        token_ids: Span<u256>,
        values: Span<u256>,
        data: Span<felt252>
    );

    /// @notice Mints a specific Fungible Token (FT).
    /// @dev Restricted to contract owner in the implementation.
    /// @param account The address to mint tokens to.
    /// @param token_id The FT ID (must NOT be an NFT ID format).
    /// @param amount The amount of the FT to mint.
    fn mint_FT(ref self: TContractState, account: ContractAddress, token_id: u256, amount: u256);

    /// @notice Mints a specific Non-Fungible Token (NFT).
    /// @dev Restricted to contract owner in the implementation. Mints supply=1.
    /// @param account The address to mint the NFT to.
    /// @param token_id The specific NFT ID (category prefix | item ID).
    fn mint_NFT(ref self: TContractState, account: ContractAddress, token_id: u256);

    // --- Metadata Function ---

    /// @notice Returns the URI for metadata associated with a token ID.
    /// @param token_id The ID of the token.
    /// @return The metadata URI string.
    fn uri(self: @TContractState, token_id: u256) -> ByteArray;

    // --- Admin Function (Owner Restricted in Implementation) ---

    /// @notice Updates the base URI for token metadata.
    /// @dev Restricted to contract owner in the implementation.
    /// @param new_base_uri The new base URI string.
    fn set_base_uri(ref self: TContractState, new_base_uri: ByteArray);
}