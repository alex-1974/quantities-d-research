module app;

import std.bigint : BigInt;
import std.stdio : writeln;

enum ProductStatus : ubyte { exact, inexact, overflow }

struct OracleResult
{
    ProductStatus status;
    BigInt value;
}

OracleResult classify(long lhs, long rhs, ulong numerator, ulong denominator)
{
    assert(denominator != 0);

    BigInt n = BigInt(lhs) * BigInt(rhs) * BigInt(numerator);
    BigInt d = BigInt(denominator);

    if (n % d != 0)
        return OracleResult(ProductStatus.inexact, BigInt(0));

    BigInt q = n / d;
    if (q < BigInt(long.min) || q > BigInt(long.max))
        return OracleResult(ProductStatus.overflow, BigInt(0));

    return OracleResult(ProductStatus.exact, q);
}

void expect(ProductStatus status, long lhs, long rhs,
            ulong numerator, ulong denominator)
{
    auto r = classify(lhs, rhs, numerator, denominator);
    assert(r.status == status);
}

void main()
{
    // Ordinary exact result.
    expect(ProductStatus.exact, 3, 4, 1, 1);

    // Exact rescale.
    auto scaled = classify(1000, 1000, 1, 1_000_000);
    assert(scaled.status == ProductStatus.exact && scaled.value == BigInt(1));

    // Rational result is not integral.
    expect(ProductStatus.inexact, 3, 4, 1, 1_000_000);

    // Integral mathematical result exists but does not fit long.
    expect(ProductStatus.overflow, long.max, 2, 1, 1);

    // Critical distinction: intermediate lhs*rhs exceeds long, but exact
    // division produces a representable result. This must be exact, not
    // overflow.
    auto cancelled = classify(long.max, 2, 1, 2);
    assert(cancelled.status == ProductStatus.exact);
    assert(cancelled.value == BigInt(long.max));

    // Same principle with an additional scale numerator.
    auto cancelledScale = classify(long.max, 2, 3, 6);
    assert(cancelledScale.status == ProductStatus.exact);
    assert(cancelledScale.value == BigInt(long.max));

    // Inexact takes precedence over representability because no integral
    // Quantity result exists at all.
    expect(ProductStatus.inexact, long.max, 2, 1, 3);

    // Negative exact endpoint.
    auto minExact = classify(long.min, 2, 1, 2);
    assert(minExact.status == ProductStatus.exact);
    assert(minExact.value == BigInt(long.min));

    // Negative overflow after exact division.
    expect(ProductStatus.overflow, long.min, 2, 1, 1);

    // A large scale numerator can itself cause result overflow.
    expect(ProductStatus.overflow, long.max, 1, 2, 1);

    writeln("R04.14 Probe 7 PASS");
    writeln("states: exact | inexact | overflow");
}
