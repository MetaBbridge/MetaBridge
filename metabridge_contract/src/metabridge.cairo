#[starknet::contract]
pub mod MetabridgeContract {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePathEntry};
    use core::array::ArrayTrait;
    use starknet::{
        get_caller_address, get_contract_address, get_block_timestamp, ContractAddress, get_tx_info
    };
    use crate::interface::metabridge::{IMetabridge, Entrepreneur, Role};
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};


    
    #[storage]
    struct Storage {
        tokenAddress: ContractAddress,
        entrepreneurs: Map::<u256, Entrepreneur>,
        entrepreneurs_id: Map::<ContractAddress, u256>,
        entrepreneur_count: u256,
        // all_business: Map::<u256, Business>,
        user_roles: Map::<ContractAddress, felt252>
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
            business_reg_id: u256,
            business_address: felt252
        ) -> Entrepreneur {
            let caller_entity = get_caller_address();
            // the check user role is the function showing missing function
            let role_status = check_user_role();

            assert(role_status == 1, 'Only an ENtrepreneur Can Register Here');

            let new_entrepreneur = Entrepreneur {
                full_name,
                email,
                date_of_birth,
                country_of_origin,
                region,
                city,
                home_address,
                business_reg_id,
                business_address,
                hasRegistered: true
            };

            self.entrepreneur_count.write(self.entrepreneur_count.read() + 1);

            self.entrepreneurs.entry(self.entrepreneur_count.read()).write(new_entrepreneur);

            self.entrepreneurs_id.entry(caller_entity).write(self.entrepreneur_count.read());

            return new_entrepreneur;

            // self.business.write(business_reg_id, new_business);
            // self.business_count.write(self.business_count.read() + 1);


            // self.all_business.write(self.business_count.read(), new_business);

            // new_business
        }
    }
}
