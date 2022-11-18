# Sui-AMM-swap

The first open source AMM swap on the [Sui](https://github.com/MystenLabs).


## cmd for tests
```bash
$ issue XBTC and USDT test coins
XBTC="0x985c26f5edba256380648d4ad84b202094a4ade3::xbtc::XBTC"
USDT="0x985c26f5edba256380648d4ad84b202094a4ade3::usdt::USDT"
SUI="0x2::sui::SUI"

$ sui client publish --gas-budget 10000
package=0xc648bfe0d87c25e0436d720ba8f296339bdba5c3
global=0x254cf7b848688aa86a8eb69677bbe2e4c46ecf50

$ sui client objects
sui_coin=0xee8cda8636da8ff86dce513567ffe0c575448567
usdt_coin=0x02b2d0736199478ba933ce2264f750233f2e4504

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $sui_coin 1 $usdt_coin 1 \
  --type-args $SUI $USDT
  
lp_sui_usdt=0xbe4df2f6772049ff6d85f6095b272f5ed74f47c4
pool_sui_usdt=0xc5f1ea9793ecc650886570c21db09dd7a4f58336

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0x4fb8f5d44bc6d123ef525bd7a50339af59c38569

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity \
  --args $global $lp_sui_usdt2 \
  --type-args $SUI $USDT

new_usdt_coin=0xcbe67728b3898197c3174cc8d8fed0bf8c9d99c8
new_sui_coin=0xfde2ee4d7ae0ebd429ef65977c13ca32fda5283f

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $new_sui_coin 1  \
  --type-args $SUI $USDT
  
out_usdt_coin=0x3bbabff1566147b3426e6cb69249e39e74607c78

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $out_usdt_coin 1 \
  --type-args $USDT $SUI

out_sui_coin=0x7ecbddd6df9b2286310c2bade3f80147ca776e8e


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $SUI $USDT
```
