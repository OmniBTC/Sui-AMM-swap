// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Defines the `Coin` type - platform wide representation of fungible
/// tokens and coins. `Coin` can be described as a secure wrapper around
/// `Balance` type.
module sui::coin {
    use sui::balance::{Self, Balance, Supply};
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;
    use std::vector;
    use sui::event;

    /// For when a type passed to create_supply is not a one-time witness.
    const EBadWitness: u64 = 0;

    /// For when invalid arguments are passed to a function.
    const EInvalidArg: u64 = 1;

    /// For when trying to split a coin more times than its balance allows.
    const ENotEnough: u64 = 2;

    /// A coin of type `T` worth `value`. Transferable and storable
    struct Coin<phantom T> has key, store {
        id: UID,
        balance: Balance<T>
    }

    /// Capability allowing the bearer to mint and burn
    /// coins of type `T`. Transferable
    struct TreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: Supply<T>
    }

    // === Events ===

    /// Emitted when new currency is created through the `create_currency` call.
    /// Contains currency metadata for off-chain discovery. Type parameter `T`
    /// matches the one in `Coin<T>`
    struct CurrencyCreated<phantom T> has copy, drop {
        /// Number of decimal places the coin uses.
        /// A coin with `value ` N and `decimals` D should be shown as N / 10^D
        /// E.g., a coin with `value` 7002 and decimals 3 should be displayed as 7.002
        /// This is metadata for display usage only.
        decimals: u8
    }

    // === Supply <-> TreasuryCap morphing and accessors  ===

    /// Return the total number of `T`'s in circulation.
    public fun total_supply<T>(cap: &TreasuryCap<T>): u64 {
        balance::supply_value(&cap.total_supply)
    }

    /// Unwrap `TreasuryCap` getting the `Supply`.
    ///
    /// Operation is irreversible. Supply cannot be converted into a `TreasuryCap` due
    /// to different security guarantees (TreasuryCap can be created only once for a type)
    public fun treasury_into_supply<T>(treasury: TreasuryCap<T>): Supply<T> {
        let TreasuryCap { id, total_supply } = treasury;
        object::delete(id);
        total_supply
    }

    /// Get immutable reference to the treasury's `Supply`.
    public fun supply<T>(treasury: &mut TreasuryCap<T>): &Supply<T> {
        &treasury.total_supply
    }

    /// Get mutable reference to the treasury's `Supply`.
    public fun supply_mut<T>(treasury: &mut TreasuryCap<T>): &mut Supply<T> {
        &mut treasury.total_supply
    }

    // === Balance <-> Coin accessors and type morphing ===

    /// Public getter for the coin's value
    public fun value<T>(self: &Coin<T>): u64 {
        balance::value(&self.balance)
    }

    /// Get immutable reference to the balance of a coin.
    public fun balance<T>(coin: &Coin<T>): &Balance<T> {
        &coin.balance
    }

    /// Get a mutable reference to the balance of a coin.
    public fun balance_mut<T>(coin: &mut Coin<T>): &mut Balance<T> {
        &mut coin.balance
    }

    /// Wrap a balance into a Coin to make it transferable.
    public fun from_balance<T>(balance: Balance<T>, ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance }
    }

    /// Destruct a Coin wrapper and keep the balance.
    public fun into_balance<T>(coin: Coin<T>): Balance<T> {
        let Coin { id, balance } = coin;
        object::delete(id);
        balance
    }

    /// Take a `Coin` worth of `value` from `Balance`.
    /// Aborts if `value > balance.value`
    public fun take<T>(
        balance: &mut Balance<T>, value: u64, ctx: &mut TxContext,
    ): Coin<T> {
        Coin {
            id: object::new(ctx),
            balance: balance::split(balance, value)
        }
    }

    /// Put a `Coin<T>` to the `Balance<T>`.
    public fun put<T>(balance: &mut Balance<T>, coin: Coin<T>) {
        balance::join(balance, into_balance(coin));
    }

    // === Base Coin functionality ===

    /// Consume the coin `c` and add its value to `self`.
    /// Aborts if `c.value + self.value > U64_MAX`
    public entry fun join<T>(self: &mut Coin<T>, c: Coin<T>) {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::join(&mut self.balance, balance);
    }

    /// Split coin `self` to two coins, one with balance `split_amount`,
    /// and the remaining balance is left is `self`.
    public fun split<T>(
        self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext
    ): Coin<T> {
        take(&mut self.balance, split_amount, ctx)
    }

    /// Split coin `self` into `n - 1` coins with equal balances. The remainder is left in
    /// `self`. Return newly created coins.
    public fun divide_into_n<T>(
        self: &mut Coin<T>, n: u64, ctx: &mut TxContext
    ): vector<Coin<T>> {
        assert!(n > 0, EInvalidArg);
        assert!(n <= value(self), ENotEnough);

        let vec = vector::empty<Coin<T>>();
        let i = 0;
        let split_amount = value(self) / n;
        while (i < n - 1) {
            vector::push_back(&mut vec, split(self, split_amount, ctx));
            i = i + 1;
        };
        vec
    }

    /// Make any Coin with a zero value. Useful for placeholding
    /// bids/payments or preemptively making empty balances.
    public fun zero<T>(ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance: balance::zero() }
    }

    /// Destroy a coin with value zero
    public fun destroy_zero<T>(c: Coin<T>) {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::destroy_zero(balance)
    }

    // === Registering new coin types and managing the coin supply ===

    /// Create a new currency type `T` as and return the `TreasuryCap` for
    /// `T` to the caller. Can only be called with a `one-time-witness`
    /// type, ensuring that there's only one `TreasuryCap` per `T`.
    public fun create_currency<T: drop>(
        witness: T,
        decimals: u8,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        // Make sure there's only one instance of the type T
        assert!(sui::types::is_one_time_witness(&witness), EBadWitness);

        // Emit Currency metadata as an event.
        event::emit(CurrencyCreated<T> {
            decimals
        });

        TreasuryCap {
            id: object::new(ctx),
            total_supply: balance::create_supply(witness)
        }
    }

    /// Create a coin worth `value`. and increase the total supply
    /// in `cap` accordingly.
    public fun mint<T>(
        cap: &mut TreasuryCap<T>, value: u64, ctx: &mut TxContext,
    ): Coin<T> {
        Coin {
            id: object::new(ctx),
            balance: balance::increase_supply(&mut cap.total_supply, value)
        }
    }

    /// Mint some amount of T as a `Balance` and increase the total
    /// supply in `cap` accordingly.
    /// Aborts if `value` + `cap.total_supply` >= U64_MAX
    public fun mint_balance<T>(
        cap: &mut TreasuryCap<T>, value: u64
    ): Balance<T> {
        balance::increase_supply(&mut cap.total_supply, value)
    }

    /// Destroy the coin `c` and decrease the total supply in `cap`
    /// accordingly.
    public fun burn<T>(cap: &mut TreasuryCap<T>, c: Coin<T>): u64 {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::decrease_supply(&mut cap.total_supply, balance)
    }

    // === Entrypoints ===

    /// Mint `amount` of `Coin` and send it to `recipient`. Invokes `mint()`.
    public entry fun mint_and_transfer<T>(
        c: &mut TreasuryCap<T>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        transfer::transfer(mint(c, amount, ctx), recipient)
    }

    /// Burn a Coin and reduce the total_supply. Invokes `burn()`.
    public entry fun burn_<T>(c: &mut TreasuryCap<T>, coin: Coin<T>) {
        burn(c, coin);
    }

    // === Test-only code ===

    #[test_only]
    /// Mint coins of any type for (obviously!) testing purposes only
    public fun mint_for_testing<T>(value: u64, ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance: balance::create_for_testing(value) }
    }

    #[test_only]
    /// Destroy a `Coin` with any value in it for testing purposes.
    public fun destroy_for_testing<T>(self: Coin<T>): u64 {
        let Coin { id, balance } = self;
        object::delete(id);
        balance::destroy_for_testing(balance)
    }
}
