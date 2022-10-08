/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module swap::controller {
  use sui::tx_context::{Self, TxContext};
  use swap::implements::{Self, Global};

  const ERR_NO_PERMISSIONS: u64 = 201;
  const ERR_ALREADY_PAUSE: u64 = 202;
  const ERR_NOT_PAUSE: u64 = 203;

  public entry fun pause(global: &mut Global, ctx: &mut TxContext){
    assert!(!implements::is_emergency(global), ERR_ALREADY_PAUSE);
    assert!(implements::pool_account(global) == tx_context::sender(ctx), ERR_NO_PERMISSIONS);
    implements::pause(global)
  }

  public entry fun resume(global: &mut Global, ctx: &mut TxContext){
    assert!(implements::is_emergency(global), ERR_NOT_PAUSE);
    assert!(implements::pool_account(global) == tx_context::sender(ctx), ERR_NO_PERMISSIONS);
    implements::resume(global)
  }
}
