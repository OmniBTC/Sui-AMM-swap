# Test coins

## cmd

```bash
# deploy on sui testnet
sui client publish --gas-budget 10000
package=0x985c26f5edba256380648d4ad84b202094a4ade3
usdt_cap_lock=0xe8d7d9615ebab5a4a76dafaae6272ae0301b2939
xbtc_cap_lock=0x0712d20475a629e5ef9a13a7c97d36bc406155b6
faucet=0x50ed67cc1d39a574301fa8d71a47419e9b297bab

# add USDT admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $usdt_cap_lock \
      0x4d7a8549beb8d9349d76a71fd4f479513622532b \
  --type-args $package::usdt::USDT

# add XBTC admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $xbtc_cap_lock \
      0x4d7a8549beb8d9349d76a71fd4f479513622532b \
  --type-args $package::xbtc::XBTC

# mint and transfer usdt
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function mint_and_transfer \
  --args $usdt_cap_lock \
      100000000 \
      0x82d770bab2d607b919f2dcc45a7491ede65fe6db \
  --type-args $package::usdt::USDT

# mint and transfer xbtc
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function mint_and_transfer \
  --args $xbtc_cap_lock \
      100000000 \
      0x82d770bab2d607b919f2dcc45a7491ede65fe6db \
  --type-args $package::xbtc::XBTC
  
# deposit usdt to faucet
# 1000000000 means 1000000000*ONE_COIN
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function mint_and_deposit \
  --args $faucet \
      $usdt_cap_lock \
      1000000000 \
  --type-args $package::usdt::USDT

usdt_in_faucet=0xd834b6228e1d2e47af5da7c842e8f9e4d292af95

# deposit xbtc to faucet
# 1000000 means 1000000*ONE_COIN
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function mint_and_deposit \
  --args $faucet \
      $xbtc_cap_lock \
      1000000 \
  --type-args $package::xbtc::XBTC
  
xbtc_in_faucet=0x86d10e108652104d452eb04e69886628f165150f

# claim usdt from faucet
# ONE_COIN = 100000000
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function claim \
  --args $faucet \
  --type-args $package::usdt::USDT
  
# claim xbtc from faucet
# ONE_COIN = 100000000
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function claim \
  --args $faucet \
  --type-args $package::xbtc::XBTC
```
