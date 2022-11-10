# Test coins

## cmd

```bash
# deploy
sui client publish --gas-budget 10000
package=0x6674cb08a6ef2a155b3c341a8697572898f0e4d1
usdt_cap_lock=0xdf324d814e75f295e10afb5388766906268fb6f3
xbtc_cap_lock=0xe96f91cf753e19fc9bd6fd62092c4fe627616cc1
faucet=0xa1edadeb50fc367837b6d37f361d6f7ee4688fdb

# add USDT admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $usdt_cap_lock \
      0x51e27b88236947063c92cc9c1b4c53565bbe0ec7 \
  --type-args $package::usdt::USDT

# add XBTC admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $xbtc_cap_lock \
      0x51e27b88236947063c92cc9c1b4c53565bbe0ec7 \
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
# 1000000 means 1000000*ONE_COIN
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function mint_and_deposit \
  --args $faucet \
      $usdt_cap_lock \
      1000000 \
  --type-args $package::usdt::USDT

usdt_in_faucet=0x7903334dffd5e8057e016b99128bb4a9f3cf1874

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
  
xbtc_in_faucet=0xeb4f442dcdadb6a33231fd7ddc3863f2e0ddfa53

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
