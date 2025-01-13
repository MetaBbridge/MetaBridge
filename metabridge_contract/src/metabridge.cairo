#[starknet::contract]
pub mod MetabridgeContract {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePathEntry};
    use core::array::ArrayTrait;
    use starknet::{
        get_caller_address, get_contract_address, get_block_timestamp, ContractAddress, get_tx_info
    };
    use crate::interface::metabridge::{IMetabridge, Entrepreneur, Role, Investor, Order, Project, Links, Milestone, Document, };
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};


    #[storage]
    struct Storage {
        tokenAddress: ContractAddress,
        entrepreneurs: Map::<u256, Entrepreneur>,
        entrepreneurs_id: Map::<ContractAddress, u256>,
        entrepreneur_count: u256,
        // all_business: Map::<u256, Business>,
        user_roles: Map::<ContractAddress, felt252>,
        investors: Map::<u256, Investor>,
        investors_count: u256,
        investors_id: Map::<ContractAddress, u256>,

        orders: Map::<u256, Order>,
        orders_count: u256,
        orders_id_created: Map::<ContractAddress, u256>,
        listed_order_count: u256,
        listed_order_id: Map::<ContractAddress, u256>,
        listed_orders: Map::<u256, u256> 
        order_to
    }

    #[abi(embed_v0)]
    impl Metabridge of IMetabridge<ContractState> {
        fn user_has_role(
            self: @ContractState
        ) -> bool {
            let user_address = get_caller_address();
            let status = self.user_roles.entry(user_address).read();
            
            if(status != 0) {
                return true;
            }
            else {
                return false;
            }
        }

        fn select_role(
            ref self: ContractState,
            roleTitle: felt252
        ) {
            let caller_addr = get_caller_address();

            let role = roleTitle; 
            self.user_roles.entry(caller_addr).write( role);

           // role
        }

        fn check_user_role(
            self: @ContractState
        ) -> felt252 {
            let user_addr = get_caller_address();
            let role_status = self.user_roles.entry(user_addr).read();

            role_status
        }


        fn register_entrepreneur(
            ref self: ContractState,
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
        ) -> Entrepreneur {
            let caller_entity = get_caller_address();
            
            let role_status = self.check_user_role();

            assert(role_status == 1, 'Only Entrepreneur Can Register');

            let new_entrepreneur = Entrepreneur {
                full_name,
                email,
                date_of_birth,
                country_of_origin,
                region,
                city,
                home_address,
                business_name,
                business_reg_id,
                business_address,
                hasRegistered: true
            };

            self.entrepreneur_count.write(self.entrepreneur_count.read() + 1);

            self.entrepreneurs.entry(self.entrepreneur_count.read()).write(new_entrepreneur);

            self.entrepreneurs_id.entry(caller_entity).write(self.entrepreneur_count.read());

            return new_entrepreneur;

        }

        fn create_order(
            ref self: ContractState,
            project: Project,
            links: Links,
            milestones: Milestone,
            team_details: felt252,
            document_upload: Document,
            tokenized_equity_offer: felt252,
            role_in_project: felt252
        ) -> u256 {
            let caller_entity = get_caller_address();

            let role_status = self.check_user_role();

            assert(role_status == 1, 'Only Entrepreneur Can Create');
            self.orders_count.write(self.orders_count.read() + 1);

            let order_id = self.orders_count.read();

            let new_order = Order {
                project,
                links,
                milestones,
                team_details,
                document_upload,
                tokenized_equity_offer,
                role_in_project,
                funding_amount_requested: 0.into()
            };

            self.orders.entry(order_id).write(new_order);
            self.orders_id_created.entry(caller_entity).write(order_id);
            
            order_id

        }

        fn list_order(
            ref self: ContractState,
            order_id: u256,
            funding_amount: felt252
        ) -> Order {
            let caller_entity = get_caller_address();
            let role_status = self.check_user_role();
            assert(role_status == 1, 'Only Entrepreneur Allowed');

            let user_order_id = self.orders_id_created.entry(caller_entity).read();
            assert(user_order_id == order_id, 'User ID does not exist');

            let mut orrder = self.orders.entry(order_id).read();
            orrder.funding_amount_requested = funding_amount;
            self.orders.entry(order_id).write(orrder);

            self.listed_order_count.write(self.listed_order_count.read() + 1);
            let listed_orrder_id = self.listed_order_count.read();

            self.listed_order_id.entry(caller_entity).write(listed_orrder_id);

            self.listed_orders.entry(order_id).write(listed_orrder_id);

            return orrder;

        }

        fn register_investor(
            ref self: ContractState,
            full_name: felt252,
            email: felt252,
            date_of_birth: felt252,
            country_of_origin: felt252,
            region: felt252,
            city: felt252,
            home_address: felt252,
            linkedin_link: felt252
        ) -> Investor {
            let user_addr = get_caller_address();

            let role_status = self.check_user_role();

            assert(role_status == 2, 'Only Investor Role Allowed');

            let inv = Investor {
                full_name,
                email,
                date_of_birth,
                country_of_origin,
                region,
                city,
                home_address,
                linkedin_link
            };

            self.investors_count.write(self.investors_count.read() + 1);
            let entrepreneur_id = self.investors_count.read();
            self.investors.entry(entrepreneur_id).write(inv);
            self.investors_id.entry(user_addr).write(entrepreneur_id);

            return inv;
        }

    }
}
