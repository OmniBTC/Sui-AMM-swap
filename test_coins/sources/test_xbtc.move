module test::xbtc {
    use sui::coin;
    use sui::tx_context::TxContext;

    use test::lock::creator_lock;

    /// XBTC for test
    struct XBTC has drop {}

    fun init(witness: XBTC, ctx: &mut TxContext) {
        let treasury_cap = coin::create_currency(
            witness,
            8,
            ctx
        );

        creator_lock(treasury_cap, ctx)
    }
}
