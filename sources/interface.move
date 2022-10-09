// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module swap::interface {
    use std::vector;
    use sui::coin::{Coin, value};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use swap::implements::{Self, Global, LP, Pool};
    use swap::event::{
        added_event, created_event, removed_event, swapped_event
    };

    const ERR_NO_PERMISSIONS: u64 = 101;
    const ERR_EMERGENCY: u64 = 102;
    const ERR_GLOBAL_MISMATCH: u64 = 103;
    const ERR_UNEXPECTED_RETURN: u64 = 104;

    /// Create new `Pool` for token `T`. Each Pool holds a `Coin<T>`
    /// and a `Coin<SUI>`. Swaps are available in both directions.
    ///
    /// Share is calculated based on Uniswap's constant product formula:
    ///  liquidity = sqrt( X * Y )
    public entry fun create_pool<T>(
        global: &Global,
        token: Coin<T>,
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        assert!(implements::pool_account(global) == tx_context::sender(ctx), ERR_NO_PERMISSIONS);

        let global_id = implements::id(global);

        let (lp, pool_id)= implements::create_pool(
            global,
            token,
            sui,
            ctx,
        );

        transfer::transfer(
            lp,
            tx_context::sender(ctx)
        );

        created_event<T>(
            global_id,
            pool_id
        )
    }

    /// Entrypoint for the `add_liquidity` method. Sends `Coin<LSP>` to
    /// the transaction sender.
    public entry fun add_liquidity<T>(
        global: &Global,
        pool: &mut Pool<T>,
        sui: Coin<SUI>,
        sui_min: u64,
        token: Coin<T>,
        token_min: u64,
        ctx: &mut TxContext
    ) {
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        let global_id = implements::global_id(pool);
        let pool_id = implements::pool_id(pool);
        assert!(global_id == implements::id(global), ERR_GLOBAL_MISMATCH);

        let (lp, return_values) = implements::add_liquidity(pool, sui, sui_min, token, token_min, ctx);
        assert!(vector::length(&return_values) == 3, ERR_UNEXPECTED_RETURN);
        let lp_tokens = vector::pop_back(&mut return_values);
        let token_val = vector::pop_back(&mut return_values);
        let sui_val = vector::pop_back(&mut return_values);

        transfer::transfer(
            lp,
            tx_context::sender(ctx)
        );

        added_event<T>(
            global_id,
            pool_id,
            sui_val,
            token_val,
            lp_tokens
        )
    }

    /// Entrypoint for the `remove_liquidity` method. Transfers
    /// withdrawn assets to the sender.
    public entry fun remove_liquidity<T>(
        global: &Global,
        pool: &mut Pool<T>,
        lp: Coin<LP<T>>,
        ctx: &mut TxContext
    ) {
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        let global_id = implements::global_id(pool);
        let pool_id = implements::pool_id(pool);
        assert!(global_id == implements::id(global), ERR_GLOBAL_MISMATCH);

        let lp_tokens = value(&lp);
        let (sui, token) = implements::remove_liquidity(pool, lp, ctx);
        let sui_val = value(&sui);
        let token_val = value(&token);

        transfer::transfer(
            sui,
            tx_context::sender(ctx)
        );

        transfer::transfer(
            token,
            tx_context::sender(ctx)
        );

        removed_event<T>(
            global_id,
            pool_id,
            sui_val,
            token_val,
            lp_tokens
        )
    }

    /// Entrypoint for the `swap_sui` method. Sends swapped token
    /// to sender.
    public entry fun swap_sui<T>(
        global: &Global,
        pool: &mut Pool<T>,
        sui: Coin<SUI>,
        token_min: u64,
        ctx: &mut TxContext
    ) {
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        let global_id = implements::global_id(pool);
        let pool_id = implements::pool_id(pool);
        assert!(global_id == implements::id(global), ERR_GLOBAL_MISMATCH);

        let (out_token, return_values) = implements::swap_sui(pool, sui, token_min, ctx);
        assert!(vector::length(&return_values) == 4, ERR_UNEXPECTED_RETURN);
        let token_out = vector::pop_back(&mut return_values);
        let token_in = vector::pop_back(&mut return_values);
        let sui_out = vector::pop_back(&mut return_values);
        let sui_in = vector::pop_back(&mut return_values);

        transfer::transfer(
            out_token,
            tx_context::sender(ctx)
        );

        swapped_event<T>(
            global_id,
            pool_id,
            sui_in,
            sui_out,
            token_in,
            token_out
        )
    }

    /// Entry point for the `swap_token` method. Sends swapped SUI
    /// to the sender.
    public entry fun swap_token<T>(
        global: &Global,
        pool: &mut Pool<T>,
        token: Coin<T>,
        sui_min: u64,
        ctx: &mut TxContext
    ) {
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        let global_id = implements::global_id(pool);
        let pool_id = implements::pool_id(pool);
        assert!(implements::global_id(pool) == implements::id(global), ERR_GLOBAL_MISMATCH);

        let (out_sui, return_values) = implements::swap_token(pool, token, sui_min, ctx);
        assert!(vector::length(&return_values) == 4, ERR_UNEXPECTED_RETURN);
        let token_out = vector::pop_back(&mut return_values);
        let token_in = vector::pop_back(&mut return_values);
        let sui_out = vector::pop_back(&mut return_values);
        let sui_in = vector::pop_back(&mut return_values);

        transfer::transfer(
            out_sui,
            tx_context::sender(ctx)
        );

        swapped_event<T>(
            global_id,
            pool_id,
            sui_in,
            sui_out,
            token_in,
            token_out
        )
    }
}
