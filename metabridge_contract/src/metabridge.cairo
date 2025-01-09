#[starknet::contract]
pub mod MetabridgeContract {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess};
    use core::array::ArrayTrait;
    use starknet::{
        get_caller_address, get_contract_address, get_block_timestamp, ContractAddress, get_tx_info
    };
    use crate::interface::metabridge::{IMetabridge, Business};
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};


    


    #[storage]
    struct Storage {
        tokenAddress: ContractAddress,
        business: Map::<u256, Business>,
        business_count: u256,
        all_business: Map::<u256, Business>,
    }

    #[abi(embed_v0)]
    impl Metabridge of IMetabridge<ContractState> {
        fn register_business(
            ref self: ContractState,
            name: felt252,
            email: felt252,
            business_reg_id: u256
        ) -> Business {
            let caller_entity = get_caller_address();

           
            let new_business = Business {
                name,
                email,
                business_reg_id,
                business_address: caller_entity
            };

            self.business.write(business_reg_id, new_business);
            self.business_count.write(self.business_count.read() + 1);


            self.all_business.write(self.business_count.read(), new_business);

            new_business
        }

        
    }
}
