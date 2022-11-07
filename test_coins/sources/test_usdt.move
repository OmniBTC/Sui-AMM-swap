module 0x0::usdt {
    use sui::tx_context::TxContext;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context;

    /// USDT for test
    struct USDT has drop {}

    fun init(witness: USDT, ctx: &mut TxContext) {
        transfer::transfer(
            coin::create_currency(witness, 8, ctx),
            tx_context::sender(ctx)
        );
    }
}
