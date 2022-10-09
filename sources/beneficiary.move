module swap::beneficiary {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use swap::implements::{Self, Global, Pool};
    use swap::event::withdrew_event;

    const ERR_NO_PERMISSIONS: u64 = 301;
    const ERR_EMERGENCY: u64 = 302;
    const ERR_GLOBAL_MISMATCH: u64 = 303;

    /// Entrypoint for the `withdraw` method.
    /// Transfers withdrew fee coins to the beneficiary.
    public entry fun withdraw<T>(
        global: &mut Global,
        pool: &mut Pool<T>,
        ctx: &mut TxContext
    ){
        assert!(!implements::is_emergency(global), ERR_EMERGENCY);
        let global_id = implements::global_id(pool);
        let pool_id = implements::pool_id(pool);
        assert!(global_id == implements::id(global), ERR_GLOBAL_MISMATCH);

        assert!(implements::beneficiary(global) == tx_context::sender(ctx), ERR_NO_PERMISSIONS);

        let (fee_sui, fee_token, sui_fee, token_fee) = implements::withdraw(pool, ctx);

        transfer::transfer(
            fee_sui,
            tx_context::sender(ctx)
        );
        transfer::transfer(
            fee_token,
            tx_context::sender(ctx)
        );

        withdrew_event<T>(
            global_id,
            pool_id,
            sui_fee,
            token_fee
        )
    }
}
