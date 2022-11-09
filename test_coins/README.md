# Test coins

## cmd

```bash
sui client publish --gas-budget 10000
package=0xbf2972612002f472b5bd21394b4417d75c9fe887
usdt_cap=0x9502728a924ff02d608f3f7d907545140e6abe46
xbtc_cap=0x6bf28d215d05ce59dbe45135f684aa7390a8d60a

sui client call \
  --gas-budget 10000 \
  --package 0x2 \
  --module coin \
  --function mint_and_transfer \
  --args $usdt_cap \
      100000000 \
      0x82d770bab2d607b919f2dcc45a7491ede65fe6db \
  --type-args $package::usdt::USDT

sui client call \
  --gas-budget 10000 \
  --package 0x2 \
  --module coin \
  --function mint_and_transfer \
  --args $xbtc_cap \
      100000000 \
      0x82d770bab2d607b919f2dcc45a7491ede65fe6db \
  --type-args $package::xbtc::XBTC


```
