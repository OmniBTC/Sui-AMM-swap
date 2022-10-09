// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.

#[test_only]
/// Refer to https://github.com/MystenLabs/sui/blob/main/sui_programmability/examples/defi/sources/pool.move#L346
///
/// Tests for the pool module.
/// They are sequential and based on top of each other.
/// ```
/// * - test_init_pool
/// |   +-- test_creation
/// |       +-- test_swap_sui
/// |           +-- test_swap_token
/// |               +-- test_withdraw_almost_all
/// |               +-- test_withdraw_all
/// ```
module swap::implements_tests {
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing as mint, destroy_for_testing as burn};
    use sui::test_scenario::{Self, Scenario, next_tx, ctx};
    use swap::implements::{Self, Pool, LP, Global};

    /// Gonna be our test token.
    struct BEEP {}

    const SUI_AMOUNT: u64 = 1000000000;
    const BEEP_AMOUNT: u64 = 1000000;

    // Tests section
    #[test] fun test_init_pool() { test_init_pool_(&mut scenario()) }
    #[test] fun test_add_liquidity() { test_add_liquidity_(&mut scenario()) }
    #[test] fun test_swap_sui() { test_swap_sui_(&mut scenario()) }
    #[test] fun test_swap_token() { test_swap_token_(&mut scenario()) }
    #[test] fun test_withdraw_almost_all() { test_withdraw_almost_all_(&mut scenario()) }
    #[test] fun test_withdraw_all() { test_withdraw_all_(&mut scenario()) }

    // Non-sequential tests
    #[test] fun test_math() { test_math_(&mut scenario()) }

    /// Init a Pool with a 1_000_000 BEEP and 1_000_000_000 SUI;
    /// Set the ratio BEEP : SUI = 1 : 1000.
    /// Set LP token amount to 1000;
    fun test_init_pool_(test: &mut Scenario) {
        let (owner, _) = people();

        next_tx(test, &owner); {
            implements::init_for_testing(ctx(test));
        };

        next_tx(test, &owner); {
            let global = test_scenario::take_shared<Global>(test);
            let global_mut = test_scenario::borrow_mut(&mut global);

            let (lp, _pool_id)= implements::create_pool(
                global_mut,
                mint<SUI>(SUI_AMOUNT, ctx(test)),
                mint<BEEP>(BEEP_AMOUNT, ctx(test)),
                ctx(test)
            );

            let burn = burn(lp);
            assert!(burn == 1000000000000000, burn);

            test_scenario::return_shared(test, global)
        };

        next_tx(test, &owner); {
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);
            let (sui_amount, token_amount, lp_supply) = implements::get_amounts(pool_mut);

            assert!(lp_supply == 1000000000000000, lp_supply);
            assert!(sui_amount == SUI_AMOUNT, 0);
            assert!(token_amount == BEEP_AMOUNT, 0);

            test_scenario::return_shared(test, pool)
        };
    }

    /// Expect LP tokens to double in supply when the same values passed
    fun test_add_liquidity_(test: &mut Scenario) {
        test_init_pool_(test);

        let (_, theguy) = people();

        next_tx(test, &theguy); {
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);
            let (sui_amount, token_amount, lp_supply) = implements::get_amounts(pool_mut);

            let (lp_tokens, _return) = implements::add_liquidity(
                pool_mut,
                mint<SUI>(sui_amount, ctx(test)),
                1,
                mint<BEEP>(token_amount, ctx(test)),
                1,
                ctx(test)
            );

            let burn = burn(lp_tokens);
            assert!(burn == lp_supply, burn);

            test_scenario::return_shared(test, pool)
        };
    }

    /// The other guy tries to exchange 5_000_000 sui for ~ 5000 BEEP,
    /// minus the commission that is paid to the pool.
    fun test_swap_sui_(test: &mut Scenario) {
        test_init_pool_(test);

        let (_, the_guy) = people();

        next_tx(test, &the_guy); {
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);

            let (token, _return) = implements::swap_sui(
                pool_mut,
                mint<SUI>(5000000, ctx(test)),
                0,
                ctx(test)
            );

            // Check the value of the coin received by the guy.
            // Due to rounding problem the value is not precise
            // (works better on larger numbers).
            assert!(burn(token) > 4950, 1);

            test_scenario::return_shared(test, pool);
        };
    }

    /// The owner swaps back BEEP for SUI and expects an increase in price.
    /// The sent amount of BEEP is 1000, initial price was 1 BEEP : 1000 SUI;
    fun test_swap_token_(test: &mut Scenario) {
        test_swap_sui_(test);

        let (owner, _) = people();

        next_tx(test, &owner); {
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);

            let (sui, _return) = implements::swap_token(
                pool_mut,
                mint<BEEP>(1000, ctx(test)),
                0,
                ctx(test)
            );

            // Actual win is 1005971, which is ~ 0.6% profit
            assert!(burn(sui) > 1000000u64, 2);

            test_scenario::return_shared(test, pool);
        };
    }

    /// Withdraw (MAX_LIQUIDITY - 1) from the pool
    fun test_withdraw_almost_all_(test: &mut Scenario) {
        test_swap_token_(test);

        let (owner, _) = people();

        // someone tries to pass MINTED_LSP and hopes there will be just 1 BEEP
        next_tx(test, &owner); {
            let lp = mint<LP<BEEP>>(1000000000000000-1, ctx(test));
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);

            let (sui, token) = implements::remove_liquidity(pool_mut, lp, ctx(test));
            let (sui_reserve, token_reserve, lp_supply) = implements::get_amounts(pool_mut);

            assert!(lp_supply == 1, 3);
            assert!(token_reserve > 0, 3); // actually 1 BEEP is left
            assert!(sui_reserve > 0, 3);

            burn(sui);
            burn(token);

            test_scenario::return_shared(test, pool);
        }
    }

    /// The owner tries to withdraw all liquidity from the pool.
    fun test_withdraw_all_(test: &mut Scenario) {
        test_swap_token_(test);

        let (owner, _) = people();

        next_tx(test, &owner); {
            let lp = mint<LP<BEEP>>(1000000000000000, ctx(test));
            let pool = test_scenario::take_shared<Pool<BEEP>>(test);
            let pool_mut = test_scenario::borrow_mut(&mut pool);

            let (sui, token) = implements::remove_liquidity(pool_mut, lp, ctx(test));
            let (sui_reserve, token_reserve, lp_supply) = implements::get_amounts(pool_mut);

            assert!(sui_reserve == 0, 3);
            assert!(token_reserve == 0, 3);
            assert!(lp_supply == 0, 3);

            let (sui_fee, token_fee, fee_sui, fee_token) = implements::withdraw<BEEP>(pool_mut, ctx(test));

            // make sure that withdrawn assets
            let burn_sui = burn(sui);
            let burn_token = burn(token);
            let burn_sui_fee = burn(sui_fee);
            let burn_token_fee = burn(token_fee);

            assert!(burn_sui_fee == fee_sui, fee_sui);
            assert!(burn_token_fee == fee_token, fee_token);
            assert!(burn_sui == 1003979044, burn_sui);
            assert!(burn_token == 996037, burn_token);

            test_scenario::return_shared(test, pool);
        };
    }

    /// This just tests the math.
    fun test_math_(_: &mut Scenario) {
        let u64_max = 18446744073709551615;
        let max_val = u64_max / 10000 - 10000;

        // Try small values
        assert!(implements::get_amount_out(10, 1000, 1000) == 9, implements::get_amount_out(10, 1000, 1000));

        // Even with 0 comission there's this small loss of 1
        assert!(implements::get_amount_out(10000, max_val , max_val) == 9969, implements::get_amount_out(10000, max_val, max_val));
        assert!(implements::get_amount_out(1000, max_val, max_val) == 996, implements::get_amount_out(1000, max_val, max_val));
        assert!(implements::get_amount_out(100, max_val, max_val) == 99, implements::get_amount_out(100, max_val, max_val));
    }

    // utilities
    fun scenario(): Scenario { test_scenario::begin(&@0x1) }
    fun people(): (address, address) { (@0xBEEF, @0x1337) }
}
