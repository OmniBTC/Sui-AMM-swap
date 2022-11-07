// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::genesis {
    use std::vector;

    use sui::balance;
    use sui::sui;
    use sui::sui_system;
    use sui::tx_context::TxContext;
    use sui::validator;
    use std::option;

    /// The initial amount of SUI locked in the storage fund.
    /// 10^14, an arbitrary number.
    const INIT_STORAGE_FUND: u64 = 100000000000000;

    /// Initial value of the lower-bound on the amount of stake required to become a validator.
    const INIT_MIN_VALIDATOR_STAKE: u64 = 100000000000000;

    /// Initial value of the upper-bound on the number of validators.
    const INIT_MAX_VALIDATOR_COUNT: u64 = 100;

    /// Initial storage gas price
    const INIT_STORAGE_GAS_PRICE: u64 = 1;

    /// This function will be explicitly called once at genesis.
    /// It will create a singleton SuiSystemState object, which contains
    /// all the information we need in the system.
    fun create(
        validator_pubkeys: vector<vector<u8>>,
        validator_network_pubkeys: vector<vector<u8>>,
        validator_proof_of_possessions: vector<vector<u8>>,
        validator_sui_addresses: vector<address>,
        validator_names: vector<vector<u8>>,
        validator_net_addresses: vector<vector<u8>>,
        validator_stakes: vector<u64>,
        validator_gas_prices: vector<u64>,
        ctx: &mut TxContext,
    ) {
        let sui_supply = sui::new(ctx);
        let storage_fund = balance::increase_supply(&mut sui_supply, INIT_STORAGE_FUND);
        let validators = vector::empty();
        let count = vector::length(&validator_pubkeys);
        assert!(
            vector::length(&validator_sui_addresses) == count
                && vector::length(&validator_stakes) == count
                && vector::length(&validator_names) == count
                && vector::length(&validator_net_addresses) == count
                && vector::length(&validator_gas_prices) == count,
            1
        );
        let i = 0;
        while (i < count) {
            let sui_address = *vector::borrow(&validator_sui_addresses, i);
            let pubkey = *vector::borrow(&validator_pubkeys, i);
            let network_pubkey = *vector::borrow(&validator_network_pubkeys, i);
            let proof_of_possession = *vector::borrow(&validator_proof_of_possessions, i);
            let name = *vector::borrow(&validator_names, i);
            let net_address = *vector::borrow(&validator_net_addresses, i);
            let stake = *vector::borrow(&validator_stakes, i);
            let gas_price = *vector::borrow(&validator_gas_prices, i);
            vector::push_back(&mut validators, validator::new(
                sui_address,
                pubkey,
                network_pubkey,
                proof_of_possession,
                name,
                net_address,
                balance::increase_supply(&mut sui_supply, stake),
                option::none(),
                gas_price,
                ctx
            ));
            i = i + 1;
        };
        sui_system::create(
            validators,
            sui_supply,
            storage_fund,
            INIT_MAX_VALIDATOR_COUNT,
            INIT_MIN_VALIDATOR_STAKE,
            INIT_STORAGE_GAS_PRICE,
        );
    }
}
