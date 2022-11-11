module test::faucet {
    use std::ascii::String;
    use std::type_name::{get, into_string};

    use sui::bag::{Self, Bag};
    use sui::balance::{Balance, zero, join, value};
    use sui::coin::{into_balance, take};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use test::lock::{Self, TreasuryLock};

    const ONE_COIN: u64 = 100000000;

    const ERR_NOT_ENOUGH_COINS: u64 = 1;
    const ERR_INVALID_AMOUNT: u64 = 2;

    struct Faucet has key {
        id: UID,
        coins: Bag
    }

    fun init(
        ctx: &mut TxContext
    ) {
        transfer::share_object(
            Faucet {
                id: object::new(ctx),
                coins: bag::new(ctx),
            }
        )
    }

    public entry fun mint_and_deposit<T>(
        faucet: &mut Faucet,
        lock: &mut TreasuryLock<T>,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        assert!(
            amount < 18446744073709551615 / ONE_COIN,
            ERR_INVALID_AMOUNT
        );

        let coin_name = into_string(get<T>());
        if (!bag::contains_with_type<String, Balance<T>>(&faucet.coins, coin_name)) {
            bag::add(&mut faucet.coins, coin_name, zero<T>());
        };

        let mut_balance = bag::borrow_mut<String, Balance<T>>(
            &mut faucet.coins,
            coin_name
        );

        join(
            mut_balance,
            into_balance(
                lock::mint(
                    lock,
                    amount * ONE_COIN,
                    ctx
                )
            )
        );
    }

    public entry fun claim<T>(
        faucet: &mut Faucet,
        ctx: &mut TxContext,
    ) {
        let coin_name = into_string(get<T>());
        assert!(
            bag::contains_with_type<String, Balance<T>>(&faucet.coins, coin_name),
            ERR_NOT_ENOUGH_COINS
        );

        let mut_balance = bag::borrow_mut<String, Balance<T>>(
            &mut faucet.coins,
            coin_name
        );

        assert!(
            value(mut_balance) >= ONE_COIN,
            ERR_NOT_ENOUGH_COINS
        );

        transfer::transfer(
            take(mut_balance, ONE_COIN, ctx),
            tx_context::sender(ctx)
        )
    }
}
