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
        Equity, Timeframe
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
        milestones_created: Map::<(u256, u256), Milestone>, // orderid to counter to Milestone
        team_created: Map::<(u256, u256), Team>,
        equity_created: Map::<(u256, u256), Equity>

    }

    #[abi(embed_v0)]
    impl Metabridge of IMetabridge<ContractState> {
        fn user_has_role(
            self: @ContractState
        ) -> bool {
            let user_address = get_caller_address();
            let status = self.user_roles.entry(user_address).read();

            if (status != 0) {
                return true;
            } else {
                return false;
            }
        }

        fn select_role(
            ref self: ContractState, 
            user_address: ContractAddress, 
            role_title: felt252
        ) {
            // let caller_addr = get_caller_address();

            self.user_roles.write(user_address, role_title);
        }

        fn check_user_role(
            self: @ContractState,
            user_address: ContractAddress
        ) -> felt252 {
            let role_status = self.user_roles.read(user_address);

            role_status
        }

        fn register_entrepreneur(
            ref self: ContractState,
            full_name: felt252,
            email: felt252,
            country_of_origin: felt252,
            state: felt252,
            home_address: felt252,
            user_address: ContractAddress
        ) -> u256 {
            // let caller_entity = get_caller_address();

            let role_status = self.check_user_role(user_address);

            assert(role_status == 1, 'Only Entrepreneur Can Register');

            let new_entrepreneur = Entrepreneur {
                full_name,
                email,
                country_of_origin,
                state,
                home_address,
                has_registered: true,
                milestone_count: 0,
                user_address,
                team_count: 0,
                equity_count: 0
            };

            self.entrepreneur_count.write(self.entrepreneur_count.read() + 1);
            
            let entree_count = self.entrepreneur_count.read();
            let new_entre = self.entrepreneurs.read(entree_count);
            let user_address = new_entre.user_address;
            
            self.entrepreneurs.entry(entree_count).write(new_entrepreneur);

            self.entrepreneurs_id.entry(user_address).write(self.entrepreneur_count.read());

            entree_count
        }

        // pub get_address(
        //     self: @ContractState,
        //     user_id: u256
        // ) -> ContractAddress {
        //     let entree_count = self.entrepreneur_count.read();
        //     let new_entre = self.entrepreneurs.read(entree_count);
        //     let user_address = new_entre.user_address;
        // }

        fn create_order(
            ref self: ContractState,
            project: Project,
            email: felt252,
            phone_no: felt252,
            location_addr: felt252,
            links: Links,
            team_details: Team,
            document_upload: Document,
            tokenized_equity_offer: Equity,
            role_in_project: felt252,
            entrepreneur_id: u256
        ) -> u256 {
            // let caller_entity = get_caller_address();

            let new_entrepreneur = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entrepreneur.user_address;

            // assert(user_address != '0000', 'Invalid Address');

            let timeframe = Timeframe {
                start_date: '',
                end_date: ''
            };

            let role_status = self.check_user_role(user_address);
            let milestone = Milestone {
                title: '',
                description: '',
                timeframe,
                req_fund_for_milestone: '',
                kpi: '',
                roi: ''
            };

            assert(role_status == 1, 'Only Entrepreneur Can Create');
            self.orders_count.write(self.orders_count.read() + 1);

            let order_id = self.orders_count.read();
            
            let new_order = Order{
                project,
                email,
                phone_no,
                location_addr,
                links,
                milestones: milestone,
                team_details,
                document_upload,
                tokenized_equity_offer,
                role_in_project,
                funding_amount_requested: 0.into(),
                verified_by_admin: false,
                amount_funded: 0.into()
            };

            self.orders.entry(order_id).write(new_order);
            self.orders_id_created.entry(user_address).write(order_id);

            order_id
        }

        fn add_milestone(
            ref self: ContractState,
            order_id: u256,
            entrepreneur_id: u256,
            milestone: Milestone
        ) -> u256 {
            // let caller_addr = get_caller_address();

            let new_entrepreneur = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entrepreneur.user_address;

            // assert(user_address != ' ', 'Invalid Address');

            let role_status = self.check_user_role(user_address);
            assert(role_status == 1, 'Entrepreneurs Only');
        
            let retrieved_id = self.orders_id_created.entry(user_address).read();
            assert(retrieved_id == order_id, 'You Cant do this!');

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let mut entre = self.entrepreneurs.entry(entre_id).read();
            entre.milestone_count += 1;

            let milestone_counter = entre.milestone_count;
            self.milestones_created.entry((order_id, milestone_counter)).write(milestone);
            let mut new_order = self.orders.entry(order_id).read();
            new_order.milestones = milestone;


            milestone_counter
            // let milestones_array = ArrayTrait::new();

            // for count in 1..milestone_counter {
            //     let milestone = self.milestones_created.entry((order_id, count)).read();
            //     milestones_array.append(milestone);
            // }
           
        }

        fn add_team(
            ref self: ContractState,
            order_id: u256,
            entrepreneur_id: u256,
            team: Team
        ) -> u256 {

            let new_entrepreneur = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entrepreneur.user_address;

            let role_status = self.check_user_role(user_address);
            assert(role_status == 1, 'Entrepreneurs Only');
        
            let retrieved_id = self.orders_id_created.entry(user_address).read();
            assert(retrieved_id == order_id, 'You Cant do this!');

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let mut entre = self.entrepreneurs.entry(entre_id).read();
            entre.team_count += 1;

            let team_counter = entre.team_count;
            self.team_created.entry((order_id, team_counter)).write(team);

            let mut new_order = self.orders.entry(order_id).read();
            new_order.team_details = team;

            team_counter
        }

        fn add_equity(
            ref self: ContractState,
            order_id: u256,
            entrepreneur_id: u256,
            equity: Equity
        ) -> u256 {
            let new_entrepreneur = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entrepreneur.user_address;

            let role_status = self.check_user_role(user_address);
            assert(role_status == 1, 'Entrepreneurs Only');
        
            let retrieved_id = self.orders_id_created.entry(user_address).read();
            assert(retrieved_id == order_id, 'You Cant do this!');

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let mut entre = self.entrepreneurs.entry(entre_id).read();
            entre.equity_count += 1;

            let team_counter = entre.team_count;
            self.equity_created.entry((order_id, team_counter)).write(equity);

            let mut new_order = self.orders.entry(order_id).read();
            new_order.tokenized_equity_offer = equity;

            team_counter
        }
        
        fn list_order(
            ref self: ContractState, 
            order_id: u256,
            entre_id: u256,
            funding_amount: u256
        ) -> Order {

            // let caller_entity = get_caller_address();

            let new_entrepreneur = self.entrepreneurs.read(entre_id);
            let user_address = new_entrepreneur.user_address;

            // assert(user_address != ' ', 'Invalid Address');

            let role_status = self.check_user_role(user_address);
            assert(role_status == 1, 'Only Entrepreneur Allowed');

            let user_order_id = self.orders_id_created.entry(user_address).read();
            assert(user_order_id == order_id, 'User ID does not exist');

            let mut orrder = self.orders.entry(order_id).read();
            let is_order_verified = orrder.verified_by_admin;

            assert(is_order_verified == true, 'Order Not Verified');

            orrder.funding_amount_requested = funding_amount;
            self.orders.entry(order_id).write(orrder);

            self.listed_order_count.write(self.listed_order_count.read() + 1);
            let listed_orrder_id = self.listed_order_count.read();

            self.listed_order_id.entry(user_address).write(listed_orrder_id);

            self.listed_orders.entry(order_id).write(listed_orrder_id);
            self.listed_order_count.write(self.listed_order_count.read() + 1);
            let listed_orrder_id = self.listed_order_count.read();

            self.listed_order_id.entry(user_address).write(listed_orrder_id);
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
            investor_address: ContractAddress
        ) -> u256 {
            // let user_addr = get_caller_address();

            let role_status = self.check_user_role(investor_address);

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
                investor_address
            };

            self.investors_count.write(self.investors_count.read() + 1);
            let investors_id = self.investors_count.read();
            self.investors.entry(investors_id).write(inv);
            self.investors_id.entry(investor_address).write(investors_id);

            return investors_id;
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
            entre_id: u256,
            investment_amount: u256
        ) -> u256 {
            // let caller_addr = get_caller_address();

            let new_entrepreneur = self.entrepreneurs.read(entre_id);
            let user_address = new_entrepreneur.user_address;

            // assert(user_address != ' ', 'Invalid Address');

            let role_status = self.check_user_role(user_address);

            assert(role_status == 2, 'Only Investor Allowed');

            let orderr = self.orders.entry(order_id).read();
            let order_status = orderr.verified_by_admin;

            assert(order_status == true, 'Order hasnt been listed');

            assert(investment_amount > 0, 'Amount Not Allowed');

            self.waiting_pool.entry(user_address).write(investment_amount);
            self.waiting_pool_list.entry(user_address).write(order_id);
            self.investor_count_for_pool_opened.entry(user_address).write(
                self.investor_count_for_pool_opened.entry(user_address).read() + 1
            );

            self.waiting_pool_id.write(self.waiting_pool_id.read() + 1);
            let pool_id = self.waiting_pool_id.read();

            self.waiting_pool_by_user_to_id.entry(user_address).write(pool_id);

            pool_id
        }

        fn commit_funds(
            ref self: ContractState,
            order_id: u256,
            listed_order_id: u256,
            entre_id: u256,
            waiting_pool_id: u256,
            commit_amount: u256
        ) -> bool {
            // let caller_addr = get_caller_address();

            let new_entrepreneur = self.entrepreneurs.read(entre_id);
            let user_address = new_entrepreneur.user_address;

            // assert(user_address != ' ', 'Invalid Address');
        
            let role_status = self.check_user_role(user_address);
            assert(role_status == 2, 'Only Investor Role Allowed');
        
            assert(commit_amount > 0, 'Invalid Commit amount');
        
            let pool_id = self.waiting_pool_by_user_to_id.entry(user_address).read();
            assert(pool_id == waiting_pool_id, 'Invalid waiting pool ID');
        
            let available_amount = self.waiting_pool.entry(user_address).read();
            assert(available_amount >= commit_amount, 'Insufficient funds');
        
            let listed_order_id_actual = self.listed_orders.entry(order_id).read();
            assert(listed_order_id_actual == listed_order_id, 'Listed order ID mismatch');
        
            let updated_balance = available_amount - commit_amount;
            self.waiting_pool.entry(user_address).write(updated_balance);
        
            let mut order = self.orders.entry(order_id).read();
            order.amount_funded = order.amount_funded + commit_amount;
            self.orders.entry(order_id).write(order);
        
            if updated_balance == 0 {
                self.waiting_pool_by_user_to_id.entry(user_address).write(0);
                self.waiting_pool_list.entry(user_address).write(0);
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

        // fn view_order_by_address(
        //     self: @ContractState,
        //     entrepreneur_address: ContractAddress
        // ) -> Array<Order> {

        // }

        fn view_order_by_address(
            self: @ContractState,
            entrepreneur_address: ContractAddress
        ) -> Order {
            let order_id = self.orders_id_created.entry(entrepreneur_address).read();
        
            assert(order_id != 0.into(), 'Order Dont Exist');
        
            let order = self.orders.entry(order_id).read();
        
            order
        }

        fn get_milestones(
            self: @ContractState,
            order_id: u256,
            entrepreneur_id: u256
        ) -> Array<Milestone> {
            let mut milestones_array = ArrayTrait::new();

            let new_entre = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entre.user_address;

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let entre = self.entrepreneurs.entry(entre_id).read();
            let m_counter = entre.milestone_count;

            for count in 1..m_counter {
                let milestone = self.milestones_created.entry((order_id, count)).read();
                milestones_array.append(milestone);
            };
    
            milestones_array
        }

        fn get_equities(
            self: @ContractState,
            order_id: u256,
            entrepreneur_id: u256
        ) -> Array<Equity> {
            let mut equities_array = ArrayTrait::new();

            let new_entre = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entre.user_address;

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let entre = self.entrepreneurs.entry(entre_id).read();
            let e_counter = entre.equity_count;

            for count in 1..e_counter {
                let equity = self.equity_created.entry((order_id, count)).read();
                equities_array.append(equity);
            };

            equities_array
        }
    
        fn get_teams(
            self: @ContractState,
            order_id: u256,
            entrepreneur_id: u256
        ) -> Array<Team> {
            let mut teams_array = ArrayTrait::new();

            let new_entre = self.entrepreneurs.read(entrepreneur_id);
            let user_address = new_entre.user_address;

            let entre_id = self.entrepreneurs_id.entry(user_address).read();
            let entre = self.entrepreneurs.entry(entre_id).read();
            let t_counter = entre.team_count;

            for count in 1..t_counter {
                let team = self.equity_created.entry((order_id, count)).read();
                teams_array.append(team);
            };
    
            teams_array
        }

        // fn get_total_entrepreneur_orders(
        //     self: @ContractState,
        //     entrepreneur_address: ContractAddress
        // ) -> u256 {
        //     let order_id = self.orders_id_created.entry(entrepreneur_address).read();

        //     assert(order_id != 0.into(), 'Address does Not Exist');

        //     let mut count: u256 = 0;

        //     let total_orders_count = self.orders_count.read();

        //     for counter in 1..total_orders_count {
                
        //     }

           

        // }
        


    }
}
