# Test coins

## cmd

```bash
# deploy
sui client publish --gas-budget 10000
package=0xa45e77f9dae08ebff5d19a831282377047eac19d
usdt_cap_lock=0x0f1f62f1a997ef677558cb40d470da38408d1d93
xbtc_cap_lock=0x3cc48d681a184e1aa76c312fb69642a2488f8263

# add USDT admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $usdt_cap_lock \
      0x21a9368d0d2daf51555739ca50ec7fd3c78eace6 \
  --type-args $package::usdt::USDT

# add XBTC admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module lock \
  --function add_admin \
  --args $xbtc_cap_lock \
      0x21a9368d0d2daf51555739ca50ec7fd3c78eace6 \
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

```
