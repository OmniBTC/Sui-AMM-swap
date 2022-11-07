// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module swap::math {

    const ERR_DIVIDE_BY_ZERO: u64 = 500;
    const ERR_U64_OVERFLOW: u64 = 501;

    const U64_MAX: u64 = 18446744073709551615;

    /// Get a nearest lower integer Square Root for `x`. Given that this
    /// function can only operate with integers, it is impossible
    /// to get perfect (or precise) integer square root for some numbers.
    ///
    /// Example:
    /// ```
    /// math::sqrt(9) => 3
    /// math::sqrt(8) => 2 // the nearest lower square root is 4;
    /// ```
    ///
    /// In integer math, one of the possible ways to get results with more
    /// precision is to use higher values or temporarily multiply the
    /// value by some bigger number. Ideally if this is a square of 10 or 100.
    ///
    /// Example:
    /// ```
    /// math::sqrt(8) => 2;
    /// math::sqrt(8 * 10000) => 282;
    /// // now we can use this value as if it was 2.82;
    /// // but to get the actual result, this value needs
    /// // to be divided by 100 (because sqrt(10000)).
    ///
    ///
    /// math::sqrt(8 * 1000000) => 2828; // same as above, 2828 / 1000 (2.828)
    /// ```
    public fun sqrt(
        x: u64
    ): u64 {
        let bit = 1u128 << 64;
        let res = 0u128;
        let x = (x as u128);

        while (bit != 0) {
            if (x >= res + bit) {
                x = x - (res + bit);
                res = (res >> 1) + bit;
            } else {
                res = res >> 1;
            };
            bit = bit >> 2;
        };

        (res as u64)
    }

    /// Implements: `x` * `y` / `z`.
    public fun mul_div(
        x: u64,
        y: u64,
        z: u64
    ): u64 {
        assert!(z != 0, ERR_DIVIDE_BY_ZERO);
        let r = (x as u128) * (y as u128) / (z as u128);
        assert!(!(r > (U64_MAX as u128)), ERR_U64_OVERFLOW);
        (r as u64)
    }

    /// Implements: `x` * `y` / `z`.
    public fun mul_div_u128(
        x: u128,
        y: u128,
        z: u128
    ): u64 {
        assert!(z != 0, ERR_DIVIDE_BY_ZERO);
        let r = x * y / z;
        assert!(!(r > (U64_MAX as u128)), ERR_U64_OVERFLOW);
        (r as u64)
    }
}
