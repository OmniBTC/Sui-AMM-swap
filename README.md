# Sui-AMM-swap

The first open source AMM swap on the [Sui](https://github.com/MystenLabs).


## cmd for tests
```bash
$ issue XBTC and USDT test coins
XBTC="0x6674cb08a6ef2a155b3c341a8697572898f0e4d1::xbtc::XBTC"
USDT="0x6674cb08a6ef2a155b3c341a8697572898f0e4d1::usdt::USDT"
SUI="0x2::sui::SUI"

$ sui client publish --gas-budget 10000
package=0x2918d7520ca9783a3ce34649c11631337e5a69a3
global=0x10638d1453b122aacdcd06ddb4bb5839d0869aa5

$ sui client objects
sui_coin=0xc334f52145d834062407a11753fe3837636c948a
usdt_coin=0x9a840cc3a9690f616f536f863440d78f53a1386d

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $sui_coin 1 $usdt_coin 1 \
  --type-args $SUI $USDT
  
lp_sui_usdt=0xc25301cf8df7963125f6eb52b3060d91ac33dda2
pool_sui_usdt=0x40e92deb82078b2af52844c0e5260d9667b8b9a0

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0xa1a092560e0cd1a7cd72d2f5e2b0329fdaf9e1cd

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity \
  --args $global $lp_sui_usdt2 \
  --type-args $SUI $USDT

new_usdt_coin=0xdc8cc73b4b59b3f0ac687d884c2ede5dfb198ed2
new_sui_coin=0x09913fcfcbb360ae25ca9e9b74bcb1ca15837b80

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $new_sui_coin 1  \
  --type-args $SUI $USDT
  
out_usdt_coin=0x6b1a804b358172d36d9eb6e0dc6261d4f00c24b1

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $out_usdt_coin 1 \
  --type-args $USDT $SUI

out_sui_coin=0x2c43cda2042f3de8dbc4336850ed20d5661f9908


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $SUI $USDT
```
