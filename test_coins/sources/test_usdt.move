module 0x0::usdt {
    use sui::coin;
    use sui::tx_context::TxContext;

    use 0x0::lock::creator_lock;

    /// USDT for test
    struct USDT has drop {}

    fun init(witness: USDT, ctx: &mut TxContext) {
        let treasury_cap = coin::create_currency(
            witness,
            8,
            ctx
        );

        creator_lock(treasury_cap, ctx)
    }
}
