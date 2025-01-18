#[starknet::contract]
pub mod MetabridgeContract {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePathEntry};
    use core::array::ArrayTrait;
    use starknet::{
        get_caller_address, get_contract_address, get_block_timestamp, ContractAddress, get_tx_info,
    };
    use crate::interface::metabridge::{
        IMetabridge, Entrepreneur, Investor, Order, Project, Links, Milestone, Document, Team,
        Equity
    };
    // use core::poseidon::PoseidonTrait;
    // use core::hash::{HashStateTrait, HashStateExTrait};


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
        listed_orders: Map::<u256, u256>,
        listed_order_to_order: Map::<u256, Order>,
        waiting_pool: Map::<ContractAddress, u256>, //address to amount
        waiting_pool_list: Map::<ContractAddress, u256>, //address to order_id
        investor_count_for_pool_opened: Map::<ContractAddress, u256>, //address to no of pool opened
        waiting_pool_id: u256,
        waiting_pool_by_user_to_id: Map::<ContractAddress, u256>,
        //milestone_collection: Map::<u256, Array<Milestone>>
        milestones_created: Map::<(u256, u256), Milestone> // orderid to counter to Milestone

    }

    #[abi(embed_v0)]
    impl Metabridge of IMetabridge<ContractState> {
        fn user_has_role(self: @ContractState) -> bool {
            let user_address = get_caller_address();
            let status = self.user_roles.entry(user_address).read();

            if (status != 0) {
                return true;
            } else {
                return false;
            }
        }

        fn select_role(ref self: ContractState, user_address: ContractAddress, roleTitle: felt252) {
            // let caller_addr = get_caller_address();            
            self.user_roles.write(user_address, roleTitle);
        }

        fn check_user_role(self: @ContractState, user_address: ContractAddress) -> felt252 {
            let role_status = self.user_roles.read(user_address);

            role_status
        }

        fn register_entrepreneur(
            ref self: ContractState,
            full_name: felt252,
            email: felt252,
            country_of_origin: felt252,
            state: felt252,
            home_address: felt252
        ) -> Entrepreneur {
            let caller_entity = get_caller_address();

            let role_status = self.check_user_role(caller_entity);

            assert(role_status == 1, 'Only Entrepreneur Can Register');

            let new_entrepreneur = Entrepreneur {
                full_name,
                email,
                country_of_origin,
                state,
                home_address,
                has_registered: true,
                milestone_count: 0
            };

            self.entrepreneur_count.write(self.entrepreneur_count.read() + 1);

            self.entrepreneurs.entry(self.entrepreneur_count.read()).write(new_entrepreneur);

            self.entrepreneurs_id.entry(caller_entity).write(self.entrepreneur_count.read());

            return new_entrepreneur;
        }

        fn create_order(
            ref self: ContractState,
            project: Project,
            email: felt252,
            phone_no: felt252,
            location_addr: felt252,
            links: Links,
            milestones: Milestone,
            team_details: Team,
            document_upload: Document,
            tokenized_equity_offer: Equity,
            role_in_project: felt252,
        ) -> u256 {
            let caller_entity = get_caller_address();

            let role_status = self.check_user_role(caller_entity);

            assert(role_status == 1, 'Only Entrepreneur Can Create');
            self.orders_count.write(self.orders_count.read() + 1);

            let order_id = self.orders_count.read();
            
            let new_order = Order {
                project,
                email,
                phone_no,
                location_addr,
                links,
                milestones,
                team_details,
                document_upload,
                tokenized_equity_offer,
                role_in_project,
                funding_amount_requested: 0.into(),
                verified_by_admin: false,
                amount_funded: 0.into()
            };

            self.orders.entry(order_id).write(new_order);
            self.orders_id_created.entry(caller_entity).write(order_id);

            order_id
        }

        fn add_milestone(
            ref self: ContractState,
            order_id: u256,
            milestone: Milestone
        ) -> u256 {
            
            let caller_addr = get_caller_address();
            let role_status = self.check_user_role(caller_addr);
            assert(role_status == 1, 'Entrepreneurs Only');
        
            let retrieved_id = self.orders_id_created.entry(caller_addr).read();
            assert(retrieved_id == order_id, 'You Cant do this!');

            let entre_id = self.entrepreneurs_id.entry(caller_addr).read();
            let mut entre = self.entrepreneurs.entry(entre_id).read();
            entre.milestone_count += 1;

            let milestone_counter = entre.milestone_count;
            self.milestones_created.entry((order_id, milestone_counter)).write(milestone);


            milestone_counter
            // let milestones_array = ArrayTrait::new();

            // for count in 1..milestone_counter {
            //     let milestone = self.milestones_created.entry((order_id, count)).read();
            //     milestones_array.append(milestone);
            // }

           
        }
        
        fn list_order(ref self: ContractState, order_id: u256, funding_amount: u256) -> Order {
            let caller_entity = get_caller_address();
            let role_status = self.check_user_role(caller_entity);
            assert(role_status == 1, 'Only Entrepreneur Allowed');

            let user_order_id = self.orders_id_created.entry(caller_entity).read();
            assert(user_order_id == order_id, 'User ID does not exist');

            let mut orrder = self.orders.entry(order_id).read();
            let is_order_verified = orrder.verified_by_admin;

            assert(is_order_verified == true, 'Order Not Verified');

            orrder.funding_amount_requested = funding_amount;
            self.orders.entry(order_id).write(orrder);

            self.listed_order_count.write(self.listed_order_count.read() + 1);
            let listed_orrder_id = self.listed_order_count.read();

            self.listed_order_id.entry(caller_entity).write(listed_orrder_id);

            self.listed_orders.entry(order_id).write(listed_orrder_id);
            self.listed_order_count.write(self.listed_order_count.read() + 1);
            let listed_orrder_id = self.listed_order_count.read();

            self.listed_order_id.entry(caller_entity).write(listed_orrder_id);
            self.listed_order_to_order.entry(listed_orrder_id).write(orrder);

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
            linkedin_link: felt252,
        ) -> Investor {
            let user_addr = get_caller_address();

            let role_status = self.check_user_role(user_addr);

            assert(role_status == 2, 'Only Investor Role Allowed');

            let inv = Investor {
                full_name,
                email,
                date_of_birth,
                country_of_origin,
                region,
                city,
                home_address,
                linkedin_link,
            };

            self.investors_count.write(self.investors_count.read() + 1);
            let entrepreneur_id = self.investors_count.read();
            self.investors.entry(entrepreneur_id).write(inv);
            self.investors_id.entry(user_addr).write(entrepreneur_id);

            return inv;
        }

        fn view_order(
            self: @ContractState, 
            listed_order: u256
        ) -> Order {
            let listed_order_id = self.listed_orders.entry(listed_order).read();
            assert(listed_order_id != 0, 'Order is not listed');

            let order_details = self.listed_order_to_order.entry(listed_order_id).read();
            return order_details;
        }

        fn invest(
            ref self: ContractState,
            order_id: u256,
            investment_amount: u256
        ) -> u256 {
            let caller_addr = get_caller_address();
            let role_status = self.check_user_role(caller_addr);

            assert(role_status == 2, 'Only Investor Allowed');

            let orderr = self.orders.entry(order_id).read();
            let order_status = orderr.verified_by_admin;

            assert(order_status == true, 'Order hasnt been listed');

            assert(investment_amount > 0, 'Amount Not Allowed');

            self.waiting_pool.entry(caller_addr).write(investment_amount);
            self.waiting_pool_list.entry(caller_addr).write(order_id);
            self.investor_count_for_pool_opened.entry(caller_addr).write(
                self.investor_count_for_pool_opened.entry(caller_addr).read() + 1
            );

            self.waiting_pool_id.write(self.waiting_pool_id.read() + 1);
            let pool_id = self.waiting_pool_id.read();

            self.waiting_pool_by_user_to_id.entry(caller_addr).write(pool_id);

            pool_id
        }

        fn commit_funds(
            ref self: ContractState,
            order_id: u256,
            listed_order_id: u256,
            waiting_pool_id: u256,
            commit_amount: u256
        ) -> bool {
            let caller_addr = get_caller_address();
        
            let role_status = self.check_user_role(caller_addr);
            assert(role_status == 2, 'Only Investor Role Allowed');
        
            assert(commit_amount > 0, 'Invalid Commit amount');
        
            let pool_id = self.waiting_pool_by_user_to_id.entry(caller_addr).read();
            assert(pool_id == waiting_pool_id, 'Invalid waiting pool ID');
        
            let available_amount = self.waiting_pool.entry(caller_addr).read();
            assert(available_amount >= commit_amount, 'Insufficient funds');
        
            let listed_order_id_actual = self.listed_orders.entry(order_id).read();
            assert(listed_order_id_actual == listed_order_id, 'Listed order ID mismatch');
        
            let updated_balance = available_amount - commit_amount;
            self.waiting_pool.entry(caller_addr).write(updated_balance);
        
            let mut order = self.orders.entry(order_id).read();
            order.amount_funded = order.amount_funded + commit_amount;
            self.orders.entry(order_id).write(order);
        
            if updated_balance == 0 {
                self.waiting_pool_by_user_to_id.entry(caller_addr).write(0);
                self.waiting_pool_list.entry(caller_addr).write(0);
            }
        
            true 
        }

        fn verify_order(
            ref self: ContractState,
            order_id: u256
        ) -> bool {
            let mut existing_orders = self.orders.entry(order_id).read();

            existing_orders.verified_by_admin = true;

            true
        }

        fn get_total_entrepreneurs(
            self: @ContractState
        ) -> Array<Entrepreneur> {
            let mut entrepreneurs_array = ArrayTrait::new();
            let entrepreneur_total = self.entrepreneur_count.read();

            for count in 1..entrepreneur_total {
                let entrepreneur = self.entrepreneurs.entry(count).read();
                entrepreneurs_array.append(entrepreneur);
            };

            entrepreneurs_array

        }

        fn view_orders(
            self: @ContractState
        ) -> Array<Order> {
            let mut all_orders = ArrayTrait::new();
            let orders_count = self.orders_count.read();

            for count in 1..orders_count {
                let orrd = self.orders.entry(count).read();
                all_orders.append(orrd);
            };

            all_orders 

        }

        fn remove_entrepreneur(
            ref self: ContractState,
            entrepreneur_id: u256
        ) -> Entrepreneur {
            let mut entre = self.entrepreneurs.entry(entrepreneur_id).read();

            entre.has_registered = false;

            entre
        }

        fn get_total_no_of_entrepreneur(
            self: @ContractState
        ) -> u256 {
            let no_of_entrepreneur = self.entrepreneur_count.read();

            no_of_entrepreneur
        }

        fn get_total_no_of_orders(
            self: @ContractState
        ) -> u256 {
            let no_of_orders = self.orders_count.read();

            no_of_orders
        }

    }
}
