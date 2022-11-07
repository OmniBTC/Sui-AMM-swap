module swap::testcoin {
    use sui::tx_context::TxContext;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context;

    /// XBTC for test
    struct XBTC has drop {}

    /// USDT for test
    struct USDT has drop {}

    fun init(ctx: &mut TxContext) {
        let xbtc_cap = coin::create_currency(XBTC{}, 8, ctx);
        let usdt_cap = coin::create_currency(XBTC{}, 6, ctx);

        transfer::transfer(xbtc_cap, tx_context::sender(ctx));
        transfer::transfer(usdt_cap, tx_context::sender(ctx));
    }
}
