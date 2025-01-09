use starknet::ContractAddress;

// Data structure layout for metabridge system

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Business {
    pub name: felt252,
    pub email: felt252,
    pub business_reg_id: u256,
    pub business_address: ContractAddress
}


#[starknet::interface]
pub trait IMetabridge<TContractState> {

    // Setter functions

    fn register_business(
        ref self: TContractState,
        name: felt252,
        email: felt252,
        business_reg_id: u256,
    ) -> Business;

    // Getter functions

}
