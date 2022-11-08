// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.

#[test_only]
/// Refer to https://github.com/MystenLabs/sui/blob/main/sui_programmability/examples/defi/sources/pool.move#L346
///
/// Tests for the pool module.
/// They are sequential and based on top of each other.
/// ```
/// * - test_add_liquidity_with_register
/// |   +-- test_add_liquidity
/// |   +-- test_swap_sui
/// |       +-- test_swap_token
/// |           +-- test_withdraw_almost_all
/// |           +-- test_withdraw_all
/// ```
module swap::implements_tests {
    use std::string::utf8;
    use std::vector;

    use sui::coin::{mint_for_testing as mint, destroy_for_testing as burn};
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario, next_tx, ctx, end};

    use swap::implements::{Self, LP, Global};

    /// Gonna be our test token.
    struct BEEP {}

    const SUI_AMOUNT: u64 = 1000000000;
    const BEEP_AMOUNT: u64 = 1000000;
    const MINIMAL_LIQUIDITY: u64 = 1000;

    // Tests section
    #[test]
    fun test_lp_name() {
        let expect_name = utf8(
            b"LP-0000000000000000000000000000000000000002::sui::SUI-0000000000000000000000000000000000000000::implements_tests::BEEP"
        );

        let lp_name = implements::generate_lp_name<SUI, BEEP>();
        assert!(lp_name == expect_name, 1);

        let lp_name = implements::generate_lp_name<BEEP, SUI>();
        assert!(lp_name == expect_name, 2);
    }

    #[test]
    fun test_add_liquidity_with_register() {
        let scenario = scenario();
        add_liquidity_with_register(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_add_liquidity() {
        let scenario = scenario();
        add_liquidity(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_swap_sui() {
        let scenario = scenario();
        swap_sui(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_swap_token() {
        let scenario = scenario();
        swap_token(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_withdraw_almost_all() {
        let scenario = scenario();
        withdraw_almost_all(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_withdraw_all() {
        let scenario = scenario();
        withdraw_all(&mut scenario);
        end(scenario);
    }

    // Non-sequential tests
    #[test]
    fun test_math() {
        let scenario = scenario();
        test_math_(&mut scenario);
        end(scenario);
    }

    /// Init a Pool with a 1_000_000 BEEP and 1_000_000_000 SUI;
    /// Set the ratio BEEP : SUI = 1 : 1000.
    /// Set LP token amount to 1000;
    fun add_liquidity_with_register(test: &mut Scenario) {
        let (owner, _) = people();

        next_tx(test, owner);
        {
            implements::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            let global = test_scenario::take_shared<Global>(test);

            let (lp, _pool_id) = implements::add_liquidity_for_testing<SUI, BEEP>(
                &mut global,
                mint<SUI>(SUI_AMOUNT, ctx(test)),
                mint<BEEP>(BEEP_AMOUNT, ctx(test)),
                ctx(test)
            );

            let burn = burn(lp);
            assert!(burn == 31621000, burn);

            test_scenario::return_shared(global)
        };

        next_tx(test, owner);
        {
            let global = test_scenario::take_shared<Global>(test);
            let pool = implements::get_mut_pool_for_testing<SUI, BEEP>(&mut global);

            let (sui_amount, token_amount, lp_supply) = implements::get_reserves_size(pool);

            assert!(lp_supply == 31621000, lp_supply);
            assert!(sui_amount == SUI_AMOUNT, 0);
            assert!(token_amount == BEEP_AMOUNT, 0);

            test_scenario::return_shared(global)
        };
    }

    /// Expect LP tokens to double in supply when the same values passed
    fun add_liquidity(test: &mut Scenario) {
        add_liquidity_with_register(test);

        let (_, theguy) = people();

        next_tx(test, theguy);
        {
            let global = test_scenario::take_shared<Global>(test);
            let pool = implements::get_mut_pool_for_testing<SUI, BEEP>(&mut global);

            let (sui_amount, token_amount, lp_supply) = implements::get_reserves_size<SUI, BEEP>(pool);

            let (lp_tokens, _returns) = implements::add_liquidity_for_testing<SUI, BEEP>(
                &mut global,
                mint<SUI>(sui_amount, ctx(test)),
                mint<BEEP>(token_amount, ctx(test)),
                ctx(test)
            );

            let burn = burn(lp_tokens);
            assert!(burn == lp_supply + MINIMAL_LIQUIDITY, burn);

            test_scenario::return_shared(global)
        };
    }

    /// The other guy tries to exchange 5_000_000 sui for ~ 5000 BEEP,
    /// minus the commission that is paid to the pool.
    fun swap_sui(test: &mut Scenario) {
        add_liquidity_with_register(test);

        let (_, the_guy) = people();

        next_tx(test, the_guy);
        {
            let global = test_scenario::take_shared<Global>(test);

            let returns = implements::swap_for_testing<SUI, BEEP>(
                &mut global,
                mint<SUI>(5000000, ctx(test)),
                0,
                ctx(test)
            );
            assert!(vector::length(&returns) == 4, vector::length(&returns));

            let coin_out = vector::borrow(&returns, 3);
            // Check the value of the coin received by the guy.
            // Due to rounding problem the value is not precise
            // (works better on larger numbers).
            assert!(*coin_out > 4950, 1);

            test_scenario::return_shared(global);
        };
    }

    /// The owner swaps back BEEP for SUI and expects an increase in price.
    /// The sent amount of BEEP is 1000, initial price was 1 BEEP : 1000 SUI;
    fun swap_token(test: &mut Scenario) {
        swap_sui(test);

        let (owner, _) = people();

        next_tx(test, owner);
        {
            let global = test_scenario::take_shared<Global>(test);

            let returns = implements::swap_for_testing<BEEP, SUI>(
                &mut global,
                mint<BEEP>(1000, ctx(test)),
                0,
                ctx(test)
            );
            assert!(vector::length(&returns) == 4, vector::length(&returns));

            let coin_out = vector::borrow(&returns, 1);
            // Actual win is 1005956, which is ~ 0.6% profit
            assert!(*coin_out > 1000000u64, 2);

            test_scenario::return_shared(global);
        };
    }

    /// Withdraw (MAX_LIQUIDITY - 1) from the pool
    fun withdraw_almost_all(test: &mut Scenario) {
        swap_token(test);

        let (owner, _) = people();

        // someone tries to pass MINTED_LSP and hopes there will be just 1 BEEP
        next_tx(test, owner);
        {
            let lp = mint<LP<SUI, BEEP>>(31621000, ctx(test));
            let global = test_scenario::take_shared<Global>(test);
            let pool = implements::get_mut_pool_for_testing<SUI, BEEP>(&mut global);

            let (sui, token) = implements::remove_liquidity_for_testing<SUI, BEEP>(pool, lp, ctx(test));
            let (sui_reserve, token_reserve, lp_supply) = implements::get_reserves_size(pool);

            assert!(lp_supply == 0, lp_supply);
            assert!(token_reserve == 0, token_reserve); // actually 1 BEEP is left
            assert!(sui_reserve == 0, sui_reserve);

            burn(sui);
            burn(token);

            test_scenario::return_shared(global);
        }
    }

    /// The owner tries to withdraw all liquidity from the pool.
    fun withdraw_all(test: &mut Scenario) {
        swap_token(test);

        let (owner, _) = people();

        next_tx(test, owner);
        {
            let lp = mint<LP<SUI, BEEP>>(31621000, ctx(test));
            let global = test_scenario::take_shared<Global>(test);
            let pool = implements::get_mut_pool_for_testing<SUI, BEEP>(&mut global);

            let (sui, token) = implements::remove_liquidity_for_testing(pool, lp, ctx(test));
            let (sui_reserve, token_reserve, lp_supply) = implements::get_reserves_size(pool);
            assert!(lp_supply == 0, lp_supply);
            assert!(sui_reserve == 0, sui_reserve);
            assert!(token_reserve == 0, token_reserve);


            let (sui_fee, token_fee, fee_sui, fee_token) = implements::withdraw_for_testing<SUI, BEEP>(
                &mut global,
                ctx(test)
            );

            // make sure that withdrawn assets
            let burn_sui = burn(sui);
            let burn_token = burn(token);
            let burn_sui_fee = burn(sui_fee);
            let burn_token_fee = burn(token_fee);

            assert!(burn_sui_fee == fee_sui, fee_sui);
            assert!(burn_token_fee == fee_token, fee_token);
            assert!(burn_sui == 1003979044, burn_sui);
            assert!(burn_token == 996037, burn_token);

            test_scenario::return_shared(global);
        };
    }

    /// This just tests the math.
    fun test_math_(_: &mut Scenario) {
        let u64_max = 18446744073709551615;
        let max_val = u64_max / 10000 - 10000;

        // Try small values
        assert!(implements::get_amount_out(10, 1000, 1000) == 9, implements::get_amount_out(10, 1000, 1000));

        // Even with 0 comission there's this small loss of 1
        assert!(
            implements::get_amount_out(10000, max_val, max_val) == 9969,
            implements::get_amount_out(10000, max_val, max_val)
        );
        assert!(
            implements::get_amount_out(1000, max_val, max_val) == 996,
            implements::get_amount_out(1000, max_val, max_val)
        );
        assert!(
            implements::get_amount_out(100, max_val, max_val) == 99,
            implements::get_amount_out(100, max_val, max_val)
        );
    }

    // utilities
    fun scenario(): Scenario { test_scenario::begin(@0x1) }

    fun people(): (address, address) { (@0xBEEF, @0x1337) }
}
