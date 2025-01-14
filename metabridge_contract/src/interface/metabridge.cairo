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

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Project {
    pub project_name: felt252,
    pub project_logo: felt252,
    pub project_description: felt252,
    pub project_story: felt252,
    pub project_usecase: felt252,
    pub problem_statement: felt252,
    pub website: felt252,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Links{
    pub github: felt252,
    pub linkedin: felt252,
    pub twitter: felt252,
    pub telegram: felt252
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Timeframe {
    pub start_date: felt252,
    pub end_date: felt252
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Milestone {
    pub title: felt252,
    pub description: felt252,
    pub timeframe: Timeframe,
    pub req_fund_for_milestone: felt252,
    pub kpi: felt252,
    pub roi: felt252
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Document {
    pub business_reg_doc: felt252,
    pub company_license: felt252,
    pub business_model: felt252,
    pub financial_statement: felt252,
    pub roadmap: felt252,
    pub pitch_deck: felt252
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Team {
    pub full_name: felt252,
    pub email: felt252,
    pub phone_no: felt252,
    pub country: felt252,
    pub state: felt252,
    pub city: felt252,
    pub location_addr: felt252,
    pub role: felt252,
    pub photo: felt252,
    pub linkedIn: felt252,
    pub links: Links
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Equity {
    pub token_equity_distribution: EquityDistribution,
    pub equity_allocation: EquityAllocation
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct EquityDistribution {
    pub totalEquity: u256,
    pub distributed_equity: u256,
    pub equity_share_offer: u256
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct EquityAllocation {
    pub equity_allocation: u256,
    pub total_equity_allocated: u256,
    pub percentage_allocation: u256
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Order {
    pub project: Project,
    pub email: felt252,
    pub phone_no: felt252,
    pub location_addr: felt252,
    pub links: Links,
    pub milestones: Milestone,
    pub team_details: felt252,
    pub document_upload: Document,
    pub tokenized_equity_offer: felt252,
    pub role_in_project: felt252,
    pub funding_amount_requested: felt252,
    pub verified_by_admin: bool,
    pub waiting_pool: Map::<ContractAddress, u256>,
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

    fn create_order(
        ref self: TContractState,
        project: Project,
        email: felt252,
        phone_no: felt252,
        location_addr: felt252,
        links: Links,
        milestones: Milestone,
        team_details: Team,
        document_upload: Document,
        tokenized_equity_offer: Equity,
        role_in_project: felt252
    ) -> u256;

    fn list_order(
        ref self: TContractState,
        order_id: u256,
        funding_amount: felt252
    ) -> Order;
   
    fn add_milestone(
        ref self: TContractState,
        order_id: u256,
        milestone: Milestone
    );
    // Getter functions
    fn user_has_role(
        self: @TContractState,
    ) -> bool;

    fn check_user_role(
        self: @TContractState
    ) -> felt252;

    fn view_order(
        self: @TContractState,
        listed_order: u256
    ) -> Order;

}
