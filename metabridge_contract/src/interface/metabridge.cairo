use starknet::ContractAddress;

// Data structure layout for metabridge system

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Entrepreneur {
    pub full_name: felt252,
    pub email: felt252,
    pub date_of_birth: felt252,
    pub country_of_origin: felt252,
    pub region: felt252,
    pub city: felt252,
    pub home_address: felt252,
    pub business_name: felt252,
    pub business_reg_id: u256,
    pub business_address: felt252,
    pub hasRegistered: bool,
    // pub teamCount: u8,
    // pub whoRegisterForCompany: felt252,
    // pub positionOfWhoRegister: felt252,
    // pub ordersListed
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Investor {
    pub full_name: felt252,
    pub email: felt252,
    pub date_of_birth: felt252,
    pub country_of_origin: felt252,
    pub region: felt252,
    pub city: felt252,
    pub home_address: felt252,
    pub linkedin_link: felt252
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Role {
    pub roleTitle: felt252,
    pub user_address: ContractAddress
}


#[starknet::interface]
pub trait IMetabridge<TContractState> {

    // Setter functions

    fn select_role(
        ref self: TContractState,
        roleTitle: felt252
    );

    fn register_entrepreneur(
        ref self: TContractState,
        full_name: felt252,
        email: felt252,
        date_of_birth: felt252,
        country_of_origin: felt252,
        region: felt252,
        city: felt252,
        home_address: felt252,
        business_name: felt252,
        business_reg_id: u256,
        business_address: felt252
    ) -> Entrepreneur;

    fn register_investor(
        ref self: TContractState,
        full_name: felt252,
        email: felt252,
        date_of_birth: felt252,
        country_of_origin: felt252,
        region: felt252,
        city: felt252,
        home_address: felt252,
        linkedin_link: felt252
    ) -> Investor;

   
    // Getter functions

    fn user_has_role(
        self: @TContractState,
    ) -> bool;

    fn check_user_role(
        self: @TContractState
    ) -> felt252;

}
