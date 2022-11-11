# Sui-AMM-swap

The first open source AMM swap on the [Sui](https://github.com/MystenLabs).


## cmd for tests
```bash
$ issue XBTC and USDT test coins
XBTC="0x07a38a173a0ff372669de25ab92901243de7f0ec::xbtc::XBTC"
USDT="0x07a38a173a0ff372669de25ab92901243de7f0ec::usdt::USDT"
SUI="0x2::sui::SUI"

$ sui client publish --gas-budget 10000
package=0xc654deb390bbdd2ab0cdd935a17ef57351f77386
global=0xed93ebb193b9cb6ba3c603c8f2ad58a606c1fb4f

$ sui client objects
sui_coin=0x0102a093c98801ed84f825c5e83d5e189db6b767
usdt_coin=0xb6c7494fbd64c7d37e89b16c7acc932affaf3cb0

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $sui_coin 1 $usdt_coin 1 \
  --type-args $SUI $USDT
  
lp_sui_usdt=0x598411b2310999ac7f9d4e3450eec16ac2d7afc3
pool_sui_usdt=0x1bac8f45cae082e0e4354387f77e3395ef888c76

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0x7d85f40ee366910a9f08cb9d66eb43d2e74960ed

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity \
  --args $global $lp_sui_usdt2 \
  --type-args $SUI $USDT

new_usdt_coin=0x71c584ed4bab17f3476fa94214eec597b94b8ed8
new_sui_coin=0x54d2dc703e8bd7e6d39f1c9b305f9c0986df7882

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $new_sui_coin 1  \
  --type-args $SUI $USDT
  
out_usdt_coin=0x66c1f5c3e916e5a2de6ba416eaa9c9fba49c6715

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $out_usdt_coin 1 \
  --type-args $USDT $SUI

out_sui_coin=0x350d24164c383b31c74fed7a1e135b25ffcbb923


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $SUI $USDT
```
