# Test coins

## cmd

```bash
# deploy on sui devnet 0.18
sui client publish --gas-budget 10000
package=0xb79c96a614a2bbf658a905d4ccae5b5e26cdcb36
faucet=0x2be30513b2d84a9b802c0824bbc96c8a665cdafe
USDT="$package::coins::USDT"
XBTC="$package::coins::XBTC"

# add faucet admin
sui client call \
  --gas-budget 10000 \
  --package $package \
  --module faucet \
  --function add_admin \
  --args $faucet \
      0xc05eaaf1369ece51ce0b8ad5cb797b737d4f2eba

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
