# Sui-AMM-swap
The first open source AMM swap on the [Sui](https://github.com/MystenLabs).

## cmd
```bash
$ issue XBTC and USDT test coins
XBTC="0xf2105964cc96221416fd7884cda044899d09e58::xbtc::XBTC"
USDT="0xf2105964cc96221416fd7884cda044899d09e58::usdt::USDT"

$ sui client publish --gas-budget 10000
package=0x6be4c594cf2761749a032d53bab76601f01ea7f7
global=0x03109c56a4728e31c264e6d48f8f34a029e4ff32

$ sui client objects
sui_coin=0xa67ce5615447b763037616dab3ff6df577b55460
usdt_coin=0xaef9f35acae75ec750bd5449d66e4e7bb2d1e85c

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=create_pool \
  --args $global $sui_coin $usdt_coin \
  --type-args $USDT
  
lp_sui_usdt=0xce5cbcadc2662fa8b9ec7f226b38fb221a627a6f
pool_sui_usdt=0xdc117aec53ba851e1fca972c95bc1c2f794bfadb

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0x400f4b6d4b69d168ce9739be2cbd5350a2c5ea8c

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity 
  --args $global $pool_sui_usdt $lp_sui_usdt2 \
  --type-args $USDT

new_usdt_coin=0x35aa28e14efa1b6050a9d469a5f566a0296b7faa
new_sui_coin=0x796e8d4eb7304d52ea8fe58d730fb7a2c827f9de

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap_sui \
  --args $global $pool_sui_usdt $new_sui_coin 1  \
  --type-args $USDT
  
out_usdt_coin=0xa4058845321c4eab466625e3fdcc9642aaca443b

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap_token \
  --args $global $pool_sui_usdt $out_usdt_coin 1 \
  --type-args $USDT

out_sui_coin=0x391501a6c85360df5d15b98285c5dea42b17dc6a


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $pool_sui_usdt $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $USDT
```
