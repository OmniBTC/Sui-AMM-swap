module 0x0::usdt {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// USDT for test
    struct USDT has drop {}

    fun init(witness: USDT, ctx: &mut TxContext) {
        transfer::transfer(
            coin::create_currency(witness, 8, ctx),
            tx_context::sender(ctx)
        );
    }
}
