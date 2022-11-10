module test::lock {
    use sui::object::{Self, UID};
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::vec_set::{Self, VecSet};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    const ERR_NO_PERMISSIONS: u64 = 1;

    /// Encapsulates the `TreasuryCap` and stores the list of mint admins.
    struct TreasuryLock<phantom T> has key {
        id: UID,
        treasury_cap: TreasuryCap<T>,
        creator: address,
        admins: VecSet<address>
    }

    public entry fun creator_lock<T>(
        treasury_cap: TreasuryCap<T>,
        ctx: &mut TxContext
    ){
        transfer::share_object(
            TreasuryLock<T> {
                id: object::new(ctx),
                treasury_cap,
                creator: tx_context::sender(ctx),
                admins: vec_set::empty<address>()
            }
        )
    }

    public entry fun add_admin<T>(
        lock: &mut TreasuryLock<T>,
        new_admin: address,
        ctx: &mut TxContext
    ){
        assert!(lock.creator == tx_context::sender(ctx), ERR_NO_PERMISSIONS);
        vec_set::insert(&mut lock.admins, new_admin)
    }

    public entry fun remove_admin<T>(
        lock: &mut TreasuryLock<T>,
        old_admin: address,
        ctx: &mut TxContext
    ){
        assert!(lock.creator == tx_context::sender(ctx), ERR_NO_PERMISSIONS);
        vec_set::remove(&mut lock.admins, &old_admin)
    }

    public entry fun mint_and_transfer<T>(
        lock: &mut TreasuryLock<T>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ){
        let operator = tx_context::sender(ctx);
        assert!(
            lock.creator == operator
                || vec_set::contains(&lock.admins, &operator),
            ERR_NO_PERMISSIONS
        );

        coin::mint_and_transfer(
            &mut lock.treasury_cap,
            amount,
            recipient,
            ctx
        )
    }

    public fun mint<T>(
        lock: &mut TreasuryLock<T>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        let operator = tx_context::sender(ctx);
        assert!(
            lock.creator == operator
                || vec_set::contains(&lock.admins, &operator),
            ERR_NO_PERMISSIONS
        );

        coin::mint(
            &mut lock.treasury_cap,
            amount,
            ctx
        )
    }
}
