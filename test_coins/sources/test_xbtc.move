module 0x0::xbtc {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// XBTC for test
    struct XBTC has drop {}

    fun init(witness: XBTC, ctx: &mut TxContext) {
        transfer::transfer(
            coin::create_currency(witness, 8, ctx),
            tx_context::sender(ctx)
        );
    }
}
