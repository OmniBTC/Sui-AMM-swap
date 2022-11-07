// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Sui object identifiers
module sui::object {
    use std::bcs;
    use sui::tx_context::{Self, TxContext};

    friend sui::dynamic_field;
    friend sui::dynamic_object_field;
    friend sui::sui_system;
    friend sui::transfer;

    #[test_only]
    friend sui::test_scenario;

    /// The hardcoded ID for the singleton Sui System State Object.
    const SUI_SYSTEM_STATE_OBJECT_ID: address = @0x5;

    /// Error from `address_from_bytes` when it is supplied too many or too few bytes.
    const EAddressParseError: u64 = 0;

    /// An object ID. This is used to reference Sui Objects.
    /// This is *not* guaranteed to be globally unique--anyone can create an `ID` from a `UID` or
    /// from an object, and ID's can be freely copied and dropped.
    /// Here, the values are not globally unique because there can be multiple values of type `ID`
    /// with the same underlying bytes. For example, `object::id(&obj)` can be called as many times
    /// as you want for a given `obj`, and each `ID` value will be identical.
    struct ID has copy, drop, store {
        // We use `address` instead of `vector<u8>` here because `address` has a more
        // compact serialization. `address` is serialized as a BCS fixed-length sequence,
        // which saves us the length prefix we would pay for if this were `vector<u8>`.
        // See https://github.com/diem/bcs#fixed-and-variable-length-sequences.
        bytes: address
    }

    /// Globally unique IDs that define an object's ID in storage. Any Sui Object, that is a struct
    /// with the `key` ability, must have `id: UID` as its first field.
    /// These are globaly unique in the sense that no two values of type `UID` are ever equal, in
    /// other words for any two values `id1: UID` and `id2: UID`, `id1` != `id2`.
    /// This is a privileged type that can only be derived from a `TxContext`.
    /// `UID` doesn't have the `drop` ability, so deleting a `UID` requires a call to `delete`.
    struct UID has store {
        id: ID,
    }

    // === address ===

    /// Convert raw bytes into an address, aborts if supplied too many
    /// or too few bytes.
    public native fun address_from_bytes(bytes: vector<u8>): address;

    // === id ===

    /// Get the raw bytes of a `ID`
    public fun id_to_bytes(id: &ID): vector<u8> {
        bcs::to_bytes(&id.bytes)
    }

    /// Get the inner bytes of `id` as an address.
    public fun id_to_address(id: &ID): address {
        id.bytes
    }

    /// Make an `ID` from raw bytes.
    public fun id_from_bytes(bytes: vector<u8>): ID {
        id_from_address(address_from_bytes(bytes))
    }

    /// Make an `ID` from an address.
    public fun id_from_address(bytes: address): ID {
        ID { bytes }
    }

    // === uid ===

    /// Create the `UID` for the singleton `SuiSystemState` object.
    /// This should only be called once from `sui_system`.
    public(friend) fun sui_system_state(): UID {
        UID {
            id: ID { bytes: SUI_SYSTEM_STATE_OBJECT_ID },
        }
    }

    /// Get the inner `ID` of `uid`
    public fun uid_as_inner(uid: &UID): &ID {
        &uid.id
    }

    /// Get the raw bytes of a `uid`'s inner `ID`
    public fun uid_to_inner(uid: &UID): ID {
        uid.id
    }

    /// Get the raw bytes of a `UID`
    public fun uid_to_bytes(uid: &UID): vector<u8> {
        bcs::to_bytes(&uid.id.bytes)
    }

    /// Get the inner bytes of `id` as an address.
    public fun uid_to_address(uid: &UID): address {
        uid.id.bytes
    }

    // === any object ===

    /// Create a new object. Returns the `UID` that must be stored in a Sui object.
    /// This is the only way to create `UID`s.
    public fun new(ctx: &mut TxContext): UID {
        UID {
            id: ID { bytes: tx_context::new_object(ctx) },
        }
    }

    /// Delete the object and it's `UID`. This is the only way to eliminate a `UID`.
    // This exists to inform Sui of object deletions. When an object
    // gets unpacked, the programmer will have to do something with its
    // `UID`. The implementation of this function emits a deleted
    // system event so Sui knows to process the object deletion
    public fun delete(id: UID) {
        let UID { id: ID { bytes } } = id;
        delete_impl(bytes)
    }

    /// Get the underlying `ID` of `obj`
    public fun id<T: key>(obj: &T): ID {
        borrow_uid(obj).id
    }

    /// Borrow the underlying `ID` of `obj`
    public fun borrow_id<T: key>(obj: &T): &ID {
        &borrow_uid(obj).id
    }

    /// Get the raw bytes for the underlying `ID` of `obj`
    public fun id_bytes<T: key>(obj: &T): vector<u8> {
        bcs::to_bytes(&borrow_uid(obj).id)
    }

    /// Get the inner bytes for the underlying `ID` of `obj`
    public fun id_address<T: key>(obj: &T): address {
        borrow_uid(obj).id.bytes
    }

    /// Get the `UID` for `obj`.
    /// Safe because Sui has an extra bytecode verifier pass that forces every struct with
    /// the `key` ability to have a distinguished `UID` field.
    /// Cannot be made public as the access to `UID` for a given object must be privledged, and
    /// restrictable in the object's module.
    native fun borrow_uid<T: key>(obj: &T): &UID;

    /// Generate a new UID specifically used for creating a UID from a hash
    public(friend) fun new_uid_from_hash(bytes: address): UID {
        record_new_uid(bytes);
        UID { id: ID { bytes } }
    }

    // === internal functions ===

    // helper for delete
    native fun delete_impl(id: address);

    // marks newly created UIDs from hash
    native fun record_new_uid(id: address);

    // Cost calibration functions
    #[test_only]
    public fun calibrate_address_from_bytes(bytes: vector<u8>) {
        address_from_bytes(bytes);
    }
    #[test_only]
    public fun calibrate_address_from_bytes_nop(bytes: vector<u8>) {
        let _ = bytes;
    }

    #[test_only]
    public fun calibrate_borrow_uid<T: key>(obj: &T) {
        borrow_uid(obj);
    }
    #[test_only]
    public fun calibrate_borrow_uid_nop<T: key>(obj: &T) {
        let _ = obj;
    }

    // TBD

    // #[test_only]
    // public fun calibrate_delete_impl(id: UID) {
    //     delete_impl(id);
    // }
    // #[test_only]
    // public fun calibrate_delete_impl(_id: UID) {
    // }

    #[test_only]
    /// Return the most recent created object ID.
    public fun last_created(ctx: &TxContext): ID {
        ID { bytes: tx_context::last_created_object_id(ctx) }
    }
}
