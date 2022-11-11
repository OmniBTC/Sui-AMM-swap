# Test coins

## cmd

```bash
# deploy on sui testnet
sui client publish --gas-budget 10000
package=0x07a38a173a0ff372669de25ab92901243de7f0ec
usdt_cap_lock=0x9c96eee244eac282b8b8b7a4548afd32500d69cd
xbtc_cap_lock=0x676e2cc59365d8d6975566832213073c7682f64d
faucet=0x7cf7b75bb4e6530d7f971702043753224d40cc01

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
# 18446744073 means 18446744073*ONE_COIN
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function mint_and_deposit \
  --args $faucet \
      $usdt_cap_lock \
      18446744073 \
  --type-args $package::usdt::USDT

usdt_in_faucet=0xb38be223e897ea5bc309b76ffe02ee9edb86d674

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
  
xbtc_in_faucet=0x1d50a57ae82664859a585d6904308bfc009c3b76

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
