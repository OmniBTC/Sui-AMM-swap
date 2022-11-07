// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sui::test_scenarioTests {
    use sui::object;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::transfer;
    use sui::tx_context;

    const ID_BYTES_MISMATCH: u64 = 0;
    const VALUE_MISMATCH: u64 = 1;
    const OBJECT_ID_NOT_FOUND: u64 = 2;

    struct Object has key, store {
        id: object::UID,
        value: u64,
    }

    struct Wrapper has key {
        id: object::UID,
        child: Object,
    }

    struct Parent has key {
        id: object::UID,
        child: object::ID,
    }

    struct MultiChildParent has key {
        id: object::UID,
        child1: object::ID,
        child2: object::ID,
    }

    #[test]
    fun test_wrap_unwrap() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
        };
        // now, object gets wrapped
        ts::next_tx(&mut scenario, sender);
        {
            let id = ts::new_object(&mut scenario);
            let child = ts::take_from_sender<Object>(&mut scenario);
            let wrapper = Wrapper { id, child };
            transfer::transfer(wrapper, copy sender);
        };
        // wrapped object should no longer be removable, but wrapper should be
        ts::next_tx(&mut scenario, sender);
        {
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0);
            assert!(ts::has_most_recent_for_sender<Wrapper>(&scenario), 1);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_remove_then_return() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
        };
        // object gets removed, then returned
        ts::next_tx(&mut scenario, sender);
        {
            let object = ts::take_from_sender<Object>(&mut scenario);
            ts::return_to_sender(&mut scenario, object);
        };
        // Object should remain accessible
        ts::next_tx(&mut scenario, sender);
        {
            assert!(ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_return_and_update() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj = ts::take_from_sender<Object>(&mut scenario);
            assert!(obj.value == 10, 0);
            obj.value = 100;
            ts::return_to_sender(&mut scenario, obj);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj = ts::take_from_sender<Object>(&mut scenario);
            assert!(obj.value == 100, 1);
            ts::return_to_sender(&mut scenario, obj);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_remove_during_tx() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
            // an object transferred during the tx shouldn't be available in that tx
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0)
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 3 /* EEmptyInventory */)]
    fun test_double_remove() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_from_sender<Object>(&mut scenario);
            let obj2 = ts::take_from_sender<Object>(&mut scenario);
            ts::return_to_sender(&mut scenario, obj1);
            ts::return_to_sender(&mut scenario, obj2);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_three_owners() {
        // make sure an object that goes from addr1 -> addr2 -> addr3 can only be accessed by
        // the appropriate owner at each stage
        let addr1 = @0x0;
        let addr2 = @0x1;
        let addr3 = @0x2;
        let scenario = ts::begin(addr1);
        {
            let id = ts::new_object(&mut scenario);
            let obj = Object { id, value: 10 };
            // self-transfer
            transfer::transfer(obj, copy addr1);
        };
        // addr1 -> addr2
        ts::next_tx(&mut scenario, addr1);
        {
            let obj = ts::take_from_sender<Object>(&mut scenario);
            transfer::transfer(obj, copy addr2)
        };
        // addr1 cannot access
        ts::next_tx(&mut scenario, addr1);
        {
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        // addr2 -> addr3
        ts::next_tx(&mut scenario, addr2);
        {
            let obj = ts::take_from_sender<Object>(&mut scenario);
            transfer::transfer(obj, copy addr3)
        };
        // addr1 cannot access
        ts::next_tx(&mut scenario, addr1);
        {
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        // addr2 cannot access
        ts::next_tx(&mut scenario, addr2);
        {
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        // addr3 *can* access
        ts::next_tx(&mut scenario, addr3);
        {
            assert!(ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_transfer_then_delete() {
        let tx1_sender = @0x0;
        let tx2_sender = @0x1;
        let scenario = ts::begin(tx1_sender);
        // send an object to tx2_sender
        let id_bytes;
        {
            let id = ts::new_object(&mut scenario);
            id_bytes = object::uid_to_inner(&id);
            let obj = Object { id, value: 100 };
            transfer::transfer(obj, copy tx2_sender);
            // sender cannot access the object
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 0);
        };
        // check that tx2_sender can get the object, and it's the same one
        ts::next_tx(&mut scenario, tx2_sender);
        {
            assert!(ts::has_most_recent_for_sender<Object>(&scenario), 1);
            let received_obj = ts::take_from_sender<Object>(&mut scenario);
            let Object { id: received_id, value } = received_obj;
            assert!(object::uid_to_inner(&received_id) == id_bytes, ID_BYTES_MISMATCH);
            assert!(value == 100, VALUE_MISMATCH);
            object::delete(received_id);
        };
        // check that the object is no longer accessible after deletion
        ts::next_tx(&mut scenario, tx2_sender);
        {
            assert!(!ts::has_most_recent_for_sender<Object>(&scenario), 2);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_get_owned_obj_ids() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        let uid2 = ts::new_object(&mut scenario);
        let uid3 = ts::new_object(&mut scenario);
        let id1 = object::uid_to_inner(&uid1);
        let id2 = object::uid_to_inner(&uid2);
        let id3 = object::uid_to_inner(&uid3);
        {
            let obj1 = Object { id: uid1, value: 10 };
            let obj2 = Object { id: uid2, value: 20 };
            let obj3 = Object { id: uid3, value: 30 };
            transfer::transfer(obj1, copy sender);
            transfer::transfer(obj2, copy sender);
            transfer::transfer(obj3, copy sender);
        };
        ts::next_tx(&mut scenario, sender);
        let ids = ts::ids_for_sender<Object>(&scenario);
        assert!(ids == vector[id1, id2, id3], VALUE_MISMATCH);
        ts::end(scenario);
    }

    #[test]
    fun test_take_owned_by_id() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        let uid2 = ts::new_object(&mut scenario);
        let uid3 = ts::new_object(&mut scenario);
        let id1 = object::uid_to_inner(&uid1);
        let id2 = object::uid_to_inner(&uid2);
        let id3 = object::uid_to_inner(&uid3);
        {
            let obj1 = Object { id: uid1, value: 10 };
            let obj2 = Object { id: uid2, value: 20 };
            let obj3 = Object { id: uid3, value: 30 };
            transfer::transfer(obj1, copy sender);
            transfer::transfer(obj2, copy sender);
            transfer::transfer(obj3, copy sender);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_from_sender_by_id<Object>(&mut scenario, id1);
            let obj3 = ts::take_from_sender_by_id<Object>(&mut scenario, id3);
            let obj2 = ts::take_from_sender_by_id<Object>(&mut scenario, id2);
            assert!(obj1.value == 10, VALUE_MISMATCH);
            assert!(obj2.value == 20, VALUE_MISMATCH);
            assert!(obj3.value == 30, VALUE_MISMATCH);
            ts::return_to_sender(&mut scenario, obj1);
            ts::return_to_sender(&mut scenario, obj2);
            ts::return_to_sender(&mut scenario, obj3);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_get_last_created_object_id() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let id_addr = object::uid_to_address(&id);
            let obj = Object { id, value: 10 };
            transfer::transfer(obj, copy sender);
            let ctx = ts::ctx(&mut scenario);
            assert!(id_addr == tx_context::last_created_object_id(ctx), 0);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_take_shared_by_id() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        let uid2 = ts::new_object(&mut scenario);
        let uid3 = ts::new_object(&mut scenario);
        let id1 = object::uid_to_inner(&uid1);
        let id2 = object::uid_to_inner(&uid2);
        let id3 = object::uid_to_inner(&uid3);
        {
            let obj1 = Object { id: uid1, value: 10 };
            let obj2 = Object { id: uid2, value: 20 };
            let obj3 = Object { id: uid3, value: 30 };
            transfer::share_object(obj1);
            transfer::share_object(obj2);
            transfer::share_object(obj3)
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_shared_by_id<Object>(&scenario, id1);
            let obj3 = ts::take_shared_by_id<Object>(&scenario, id3);
            let obj2 = ts::take_shared_by_id<Object>(&scenario, id2);
            assert!(obj1.value == 10, VALUE_MISMATCH);
            assert!(obj2.value == 20, VALUE_MISMATCH);
            assert!(obj3.value == 30, VALUE_MISMATCH);
            ts::return_shared(obj1);
            ts::return_shared(obj2);
            ts::return_shared(obj3);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_take_shared() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        {
            let obj1 = Object { id: uid1, value: 10 };
            transfer::share_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        {
            assert!(ts::has_most_recent_shared<Object>(), 1);
            let obj1 = ts::take_shared<Object>(&mut scenario);
            assert!(obj1.value == 10, VALUE_MISMATCH);
            ts::return_shared(obj1);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_take_immutable_by_id() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        let uid2 = ts::new_object(&mut scenario);
        let uid3 = ts::new_object(&mut scenario);
        let id1 = object::uid_to_inner(&uid1);
        let id2 = object::uid_to_inner(&uid2);
        let id3 = object::uid_to_inner(&uid3);
        {
            let obj1 = Object { id: uid1, value: 10 };
            let obj2 = Object { id: uid2, value: 20 };
            let obj3 = Object { id: uid3, value: 30 };
            transfer::freeze_object(obj1);
            transfer::freeze_object(obj2);
            transfer::freeze_object(obj3)
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_immutable_by_id<Object>(&scenario, id1);
            let obj3 = ts::take_immutable_by_id<Object>(&scenario, id3);
            let obj2 = ts::take_immutable_by_id<Object>(&scenario, id2);
            assert!(obj1.value == 10, VALUE_MISMATCH);
            assert!(obj2.value == 20, VALUE_MISMATCH);
            assert!(obj3.value == 30, VALUE_MISMATCH);
            ts::return_immutable(obj1);
            ts::return_immutable(obj2);
            ts::return_immutable(obj3);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_take_immutable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        {
            let obj1 = Object { id: uid1, value: 10 };
            transfer::freeze_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        {
            assert!(ts::has_most_recent_immutable<Object>(), 1);
            let obj1 = ts::take_immutable<Object>(&mut scenario);
            assert!(obj1.value == 10, VALUE_MISMATCH);
            ts::return_immutable(obj1);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_unreturned_objects() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid1 = ts::new_object(&mut scenario);
        let uid2 = ts::new_object(&mut scenario);
        let uid3 = ts::new_object(&mut scenario);
        {
            transfer::share_object(Object { id: uid1, value: 10 });
            transfer::freeze_object(Object { id: uid2, value: 10 });
            transfer::transfer(Object { id: uid3, value: 10 }, sender);
        };
        ts::next_tx(&mut scenario, sender);
        let shared = ts::take_shared<Object>(&scenario);
        let imm = ts::take_immutable<Object>(&scenario);
        let owned = ts::take_from_sender<Object>(&scenario);
        ts::next_tx(&mut scenario, sender);
        ts::next_epoch(&mut scenario, sender);
        ts::next_tx(&mut scenario, sender);
        ts::next_epoch(&mut scenario, sender);
        ts::end(scenario);
        transfer::share_object(shared);
        transfer::freeze_object(imm);
        transfer::transfer(owned, sender);
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_invalid_shared_usage() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj1 = Object { id, value: 10 };
            transfer::share_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_shared<Object>(&mut scenario);
            transfer::freeze_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_invalid_immutable_usage() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj1 = Object { id, value: 10 };
            transfer::freeze_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        {
            let obj1 = ts::take_immutable<Object>(&mut scenario);
            transfer::share_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_modify_immutable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        {
            let id = ts::new_object(&mut scenario);
            let obj1 = Object { id, value: 10 };
            transfer::freeze_object(obj1);
        };
        ts::next_tx(&mut scenario, sender);
        let obj1 = ts::take_immutable<Object>(&mut scenario);
        ts::next_tx(&mut scenario, sender);
        obj1.value = 100;
        ts::next_tx(&mut scenario, sender);
        ts::return_immutable(obj1);
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 2 /* ECantReturnObject */)]
    fun test_invalid_address_return() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let id = ts::new_object(&mut scenario);
        ts::return_to_sender(&scenario, Object { id, value: 10 });
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 2 /* ECantReturnObject */)]
    fun test_invalid_shared_return() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let id = ts::new_object(&mut scenario);
        ts::return_shared(Object { id, value: 10 });
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 2 /* ECantReturnObject */)]
    fun test_invalid_immutable_return() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let id = ts::new_object(&mut scenario);
        ts::return_immutable(Object { id, value: 10 });
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 3 /* EEmptyInventory */)]
    fun test_empty_inventory() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        ts::return_to_sender(&scenario, ts::take_from_sender<Object>(&scenario));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 3 /* EEmptyInventory */)]
    fun test_empty_inventory_shared() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        ts::return_to_sender(&scenario, ts::take_shared<Object>(&scenario));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 3 /* EEmptyInventory */)]
    fun test_empty_inventory_immutable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        ts::return_to_sender(&scenario, ts::take_immutable<Object>(&scenario));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_object_not_found() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        ts::return_to_sender(&scenario, ts::take_from_sender_by_id<Object>(&scenario, id));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_object_not_found_shared() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        ts::return_to_sender(&scenario, ts::take_shared_by_id<Object>(&scenario, id));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_object_not_found_immutable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        ts::return_to_sender(&scenario, ts::take_immutable_by_id<Object>(&scenario, id));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_wrong_object_type() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        transfer::transfer(Object { id: uid, value: 10 }, sender);
        ts::return_to_sender(&scenario, ts::take_from_sender_by_id<Wrapper>(&scenario, id));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_wrong_object_type_shared() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        transfer::share_object(Object { id: uid, value: 10 });
        ts::return_shared(ts::take_shared_by_id<Wrapper>(&scenario, id));
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 4 /* EObjectNotFound */)]
    fun test_wrong_object_type_immutable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let uid = ts::new_object(&mut scenario);
        let id = object::uid_to_inner(&uid);
        transfer::freeze_object(Object { id: uid, value: 10 });
        ts::return_immutable(ts::take_immutable_by_id<Wrapper>(&scenario, id));
        abort 42
    }

    #[test]
    fun test_dynamic_field_still_borrowed() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        sui::dynamic_field::add(&mut parent, b"", 10);
        let r = sui::dynamic_field::borrow<vector<u8>, u64>(&mut parent, b"");
        ts::end(scenario);
        assert!(*r == 10, 0);
        object::delete(parent);
    }

    #[test]
    fun test_dynamic_object_field_still_borrowed() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let id = ts::new_object(&mut scenario);
        sui::dynamic_object_field::add(&mut parent, b"", Object { id, value: 10});
        let obj = sui::dynamic_object_field::borrow<vector<u8>, Object>(&mut parent, b"");
        ts::end(scenario);
        assert!(obj.value == 10, 0);
        object::delete(parent);
    }

    #[test]
    fun test_dynamic_object_field_not_retrievable() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let uid = ts::new_object(&mut scenario);
        let obj = Object { id: uid, value: 10};
        let id = object::id(&obj);
        transfer::transfer(obj, sender);
        ts::next_tx(&mut scenario, sender);
        assert!(ts::has_most_recent_for_address<Object>(sender), 0);
        let obj = ts::take_from_sender<Object>(&mut scenario);
        assert!(object::id(&obj) == id, 0);
        assert!(!ts::has_most_recent_for_address<Object>(sender), 0);
        sui::dynamic_object_field::add(&mut parent, b"", obj);
        ts::next_tx(&mut scenario, sender);
        assert!(!ts::has_most_recent_for_address<Object>(sender), 0);
        ts::end(scenario);
        object::delete(parent);
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_dynamic_field_shared_misuse() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let uid = ts::new_object(&mut scenario);
        let obj = Object { id: uid, value: 10};
        let id = object::id(&obj);
        transfer::share_object(obj);
        ts::next_tx(&mut scenario, sender);
        let obj = ts::take_shared<Object>(&mut scenario);
        assert!(object::id(&obj) == id, 0);
        // wraps the object
        sui::dynamic_field::add(&mut parent, b"", obj);
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_dynamic_field_immutable_misuse() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let uid = ts::new_object(&mut scenario);
        let obj = Object { id: uid, value: 10};
        let id = object::id(&obj);
        transfer::freeze_object(obj);
        ts::next_tx(&mut scenario, sender);
        let obj = ts::take_immutable<Object>(&mut scenario);
        assert!(object::id(&obj) == id, 0);
        // wraps the object
        sui::dynamic_field::add(&mut parent, b"", obj);
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

        #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_dynamic_object_field_shared_misuse() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let uid = ts::new_object(&mut scenario);
        let obj = Object { id: uid, value: 10};
        let id = object::id(&obj);
        transfer::share_object(obj);
        ts::next_tx(&mut scenario, sender);
        let obj = ts::take_shared<Object>(&mut scenario);
        assert!(object::id(&obj) == id, 0);
        sui::dynamic_object_field::add(&mut parent, b"", obj);
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = 1 /* EInvalidSharedOrImmutableUsage */)]
    fun test_dynamic_object_field_immutable_misuse() {
        let sender = @0x0;
        let scenario = ts::begin(sender);
        let parent = ts::new_object(&mut scenario);
        let uid = ts::new_object(&mut scenario);
        let obj = Object { id: uid, value: 10};
        let id = object::id(&obj);
        transfer::freeze_object(obj);
        ts::next_tx(&mut scenario, sender);
        let obj = ts::take_immutable<Object>(&mut scenario);
        assert!(object::id(&obj) == id, 0);
        sui::dynamic_object_field::add(&mut parent, b"", obj);
        ts::next_tx(&mut scenario, sender);
        abort 42
    }

    /// Create an object and transfer it to the sender of `scenario`.
    fun create_and_transfer_object(scenario: &mut Scenario, value: u64) {
        let object = Object {
            id: ts::new_object(scenario),
            value,
        };
        transfer::transfer(object, ts::sender(scenario));
    }
}
