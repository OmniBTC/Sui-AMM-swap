// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module swap::event {
    use sui::event::emit;
    use sui::object::ID;

    /// Liquidity pool created event.
    struct CreatedEvent<phantom T> has copy, drop {
        global: ID,
        pool: ID,
    }

    /// Liquidity pool added event.
    struct AddedEvent<phantom T> has copy, drop {
        global: ID,
        pool: ID,
        sui_val: u64,
        token_val: u64,
        lp_tokens: u64,
    }

    /// Liquidity pool removed event.
    struct RemovedEvent<phantom T> has copy, drop {
        global: ID,
        pool: ID,
        sui_val: u64,
        token_val: u64,
        lp_tokens: u64,
    }

    /// Liquidity pool swapped event.
    struct SwappedEvent<phantom T> has copy, drop {
        global: ID,
        pool: ID,
        sui_in: u64,
        sui_out: u64,
        token_in: u64,
        token_out: u64,
    }

    /// Liquidity pool withdrew fee coins event.
    struct WithdrewEvent<phantom T> has copy, drop {
        global: ID,
        pool: ID,
        sui_fee: u64,
        token_fee: u64
    }

    public fun created_event<T>(
        global: ID,
        pool: ID,
    ) {
        emit(
            CreatedEvent<T> {
                global,
                pool
            }
        )
    }

    public fun added_event<T>(
        global: ID,
        pool: ID,
        sui_val: u64,
        token_val: u64,
        lp_tokens: u64
    ) {
        emit(
            AddedEvent<T> {
                global,
                pool,
                sui_val,
                token_val,
                lp_tokens
            }
        )
    }

    public fun removed_event<T>(
        global: ID,
        pool: ID,
        sui_val: u64,
        token_val: u64,
        lp_tokens: u64
    ) {
        emit(
            RemovedEvent<T> {
                global,
                pool,
                sui_val,
                token_val,
                lp_tokens
            }
        )
    }

    public fun swapped_event<T>(
        global: ID,
        pool: ID,
        sui_in: u64,
        sui_out: u64,
        token_in: u64,
        token_out: u64
    ) {
        emit(
            SwappedEvent<T> {
                global,
                pool,
                sui_in,
                sui_out,
                token_in,
                token_out
            }
        )
    }

    public fun withdrew_event<T>(
        global: ID,
        pool: ID,
        sui_fee: u64,
        token_fee: u64,
    ) {
        emit(
            WithdrewEvent<T> {
                global,
                pool,
                sui_fee,
                token_fee
            }
        )
    }
}
