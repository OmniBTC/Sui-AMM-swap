# Sui-AMM-swap

The first open source AMM swap on the [Sui](https://github.com/MystenLabs).


## cmd for tests
```bash
$ issue XBTC and USDT test coins
XBTC="0xb79c96a614a2bbf658a905d4ccae5b5e26cdcb36::coins::XBTC"
USDT="0xb79c96a614a2bbf658a905d4ccae5b5e26cdcb36::coins::USDT"
SUI="0x2::sui::SUI"

$ sui client publish --gas-budget 10000
package=0x1a5d746c243abc6dd1c0bd0a710e1d79881f0aef
global=0xd6138a04638992f94ed84bdb214034f363ed1a4f

$ sui client objects
sui_coin=0x525c0eb0e1f4d8744ae21984de2e8a089366a557
usdt_coin=0x8e81c2362ff1e7101b2ef2a0d1ff9b3c358a1ac9

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $sui_coin 1 $usdt_coin 1 \
  --type-args $SUI $USDT
  
lp_sui_usdt=0xdf622fddc8447b0c1d15f8418e010933dd5f0a6c 
pool_sui_usdt=0x5058b90e728df97c4cb5cade5e5c77fcb662a4b9

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0x6cde2fe9277c92e196585fb12c6e3d5aaa4eab34

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity \
  --args $global $lp_sui_usdt2 \
  --type-args $SUI $USDT

new_usdt_coin=0xc090e45f9461e39abb0452cf3ec297a40efbfdc3
new_sui_coin=0x9c8c1cc38cc61a94264911933c69a772ced07a09

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $new_sui_coin 1  \
  --type-args $SUI $USDT
  
out_usdt_coin=0x80076d95c8bd1d5a0f97b537669008a1a369ce12

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $out_usdt_coin 1 \
  --type-args $USDT $SUI

out_sui_coin=0xaa89836115e1e1a4f5fa990ebd2c7be3a5124d07


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $SUI $USDT
```
