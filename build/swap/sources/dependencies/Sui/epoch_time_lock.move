// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::epoch_time_lock {
    use sui::tx_context::{Self, TxContext};

    /// The epoch passed into the creation of a lock has already passed.
    const EEpochAlreadyPassed: u64 = 0;

    /// Attempt is made to unlock a lock that cannot be unlocked yet.
    const EEpochNotYetEnded: u64 = 1;

    /// Holder of an epoch number that can only be discarded in the epoch or
    /// after the epoch has passed.
    struct EpochTimeLock has store, copy {
        epoch: u64
    }

    /// Create a new epoch time lock with `epoch`. Aborts if the current epoch is less than the input epoch.
    public fun new(epoch: u64, ctx: &mut TxContext) : EpochTimeLock {
        assert!(tx_context::epoch(ctx) < epoch, EEpochAlreadyPassed);
        EpochTimeLock { epoch }
    }

    /// Destroys an epoch time lock. Aborts if the current epoch is less than the locked epoch.
    public fun destroy(lock: EpochTimeLock, ctx: &mut TxContext) {
        let EpochTimeLock { epoch } = lock;
        assert!(tx_context::epoch(ctx) >= epoch, EEpochNotYetEnded);
    }

    /// Getter for the epoch number.
    public fun epoch(lock: &EpochTimeLock): u64 {
        lock.epoch
    }
}
