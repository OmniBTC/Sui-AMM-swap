# Test coins

## cmd

```bash
# deploy on sui testnet
sui client publish --gas-budget 10000
package=0xc7fb1756b094e8d3ae5f766ff5800b89e31bd72a
faucet=0xef48dfe069d691da85e5195559264e96c0817850
USDT="0xc7fb1756b094e8d3ae5f766ff5800b89e31bd72a::coins::USDT"
XBTC="0xc7fb1756b094e8d3ae5f766ff5800b89e31bd72a::coins::XBTC"

# add faucet admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function add_admin \
  --args $faucet \
      0x4d7a8549beb8d9349d76a71fd4f479513622532b

# claim usdt
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function claim \
  --args $faucet \
  --type-args $USDT

# force claim xbtc with amount
# 10 means 10*ONE_COIN
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function force_claim \
  --args $faucet 10 \
  --type-args $XBTC

# add new coin supply
PCX_CAP=0xfe6db5a5802acb32b566d7b7d1fbdf55a496eb7f
PCX="0x44984b1d38594dc64a380391359b46ae4207d165::pcx::PCX"
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function add_supply \
  --args $faucet \
         $PCX_CAP \
  --type-args $PCX
```
