# Sui-AMM-swap

The first open source AMM swap on the [Sui](https://github.com/MystenLabs).


## cmd for tests
```bash
$ issue XBTC and USDT test coins
XBTC="0xbf2972612002f472b5bd21394b4417d75c9fe887::xbtc::XBTC"
USDT="0xbf2972612002f472b5bd21394b4417d75c9fe887::usdt::USDT"
SUI="0x2::sui::SUI"

$ sui client publish --gas-budget 10000
package=0x6b2b8d00733280d641a506e3865de71a0e9398e9
global=0xa65f9fb71b9989c7bb530c2c077e5decc7fe1d9d

$ sui client objects
sui_coin=0x37d5f74685af5bcbed7eb338420defe30a079bf7
usdt_coin=0x0c24af61435fabeff072b4eb26bd73feb4a39c1e

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $sui_coin 1 $usdt_coin 1 \
  --type-args $SUI $USDT
  
lp_sui_usdt=0x87ab31d7f08e08b7be2855b949210f22e697a736
pool_sui_usdt=0x36741a767c1cb037be436c6e40d0b40615309a8a

$ sui client split-coin --gas-budget 10000 \
  --coin-id $lp_sui_usdt \
  --amounts 100000
  
lp_sui_usdt2=0xedeecc62d9a04ad5de9d151dfaf29f2b7fb6bc29

$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=remove_liquidity \
  --args $global $lp_sui_usdt2 \
  --type-args $SUI $USDT

new_usdt_coin=0x80363102346064f5044c830468e6cf5f3a44fff0
new_sui_coin=0xc77d063b109542662bb980c9422b1b878d7e8c80

# sui -> usdt
$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $new_sui_coin 1  \
  --type-args $SUI $USDT
  
out_usdt_coin=0x24daa0d93cc5b665e9abbd6f744df68c39717423

# usdt -> sui
sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=swap \
  --args $global $out_usdt_coin 1 \
  --type-args $USDT $SUI

out_sui_coin=0xfd950466da82c42a4cb35eb54df3a1a8dfcf5c09


$ sui client call --gas-budget 10000 \
  --package=$package \
  --module=interface \
  --function=add_liquidity \
  --args $global $out_sui_coin 100 $new_usdt_coin 1000 \
  --type-args $SUI $USDT
```
