// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module swap::interface {
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use swap::implements::{Self, Global, LP, Pool};

    const ERR_NO_PERMISSIONS: u64 = 101;
    const ERR_EMERGENCY: u64 = 102;
    const ERR_GLOBAL_MISMATCH: u64 = 103;

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

        let lp = implements::create_pool(
            global,
            token,
            sui,
            ctx,
        );

        transfer::transfer(
            lp,
            tx_context::sender(ctx)
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
        assert!(implements::global_id(pool) == implements::id(global), ERR_GLOBAL_MISMATCH);

        transfer::transfer(
            implements::add_liquidity(pool, sui, sui_min, token, token_min, ctx),
            tx_context::sender(ctx)
        );
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
        assert!(implements::global_id(pool) == implements::id(global), ERR_GLOBAL_MISMATCH);

        let (sui, token) = implements::remove_liquidity(pool, lp, ctx);

        transfer::transfer(
            sui,
            tx_context::sender(ctx)
        );

        transfer::transfer(
            token,
            tx_context::sender(ctx)
        );
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
        assert!(implements::global_id(pool) == implements::id(global), ERR_GLOBAL_MISMATCH);

        transfer::transfer(
            implements::swap_sui(pool, sui, token_min, ctx),
            tx_context::sender(ctx)
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
        assert!(implements::global_id(pool) == implements::id(global), ERR_GLOBAL_MISMATCH);

        transfer::transfer(
            implements::swap_token(pool, token, sui_min, ctx),
            tx_context::sender(ctx)
        )
    }
}
