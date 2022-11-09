# Test coins

## cmd

```bash
sui client publish --gas-budget 10000
package=0x0f2105964cc96221416fd7884cda044899d09e58
usdt_cap=0x7886a7a915869fc4e4ada771a14e02ec8133d2cf
xbtc_cap=0x4bde68a12ccde96bd1b276dda1124679d2cbc69b

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
