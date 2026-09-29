module r04_13_exact_quotient_kernel_probe;

import std.traits : isIntegral;

// Probe 4: exact integral kernel for
//
//     lhs * scaleNumerator
//     --------------------
//     rhs * scaleDenominator
//
// The algorithm works on unsigned magnitudes, tracks sign separately, and
// cross-cancels before multiplication. This avoids -long.min and many
// unnecessary intermediate overflows. The probe intentionally uses ulong as
// its bounded magnitude domain; it is not yet the production Rep policy.

enum QuotientStatus : ubyte
{
    exact,
    inexact,
    overflow,
    divisionByZero
}

struct Result
{
    QuotientStatus status;
    bool negative;
    ulong magnitude;
}

private ulong magnitude(long value) @safe pure nothrow @nogc
{
    if (value >= 0)
        return cast(ulong)value;
    return cast(ulong)(-(value + 1)) + 1UL;
}

private ulong gcd(ulong a, ulong b) @safe pure nothrow @nogc
{
    while (b != 0)
    {
        const r = a % b;
        a = b;
        b = r;
    }
    return a;
}

private bool checkedMul(
    ulong a, ulong b, out ulong result) @safe pure nothrow @nogc
{
    if (a != 0 && b > ulong.max / a)
        return false;
    result = a * b;
    return true;
}

Result exactScaledQuotient(
    long lhs,
    long rhs,
    ulong scaleNumerator,
    ulong scaleDenominator) @safe pure nothrow @nogc
{
    assert(scaleNumerator != 0);
    assert(scaleDenominator != 0);

    if (rhs == 0)
        return Result(QuotientStatus.divisionByZero, false, 0);

    if (lhs == 0)
        return Result(QuotientStatus.exact, false, 0);

    bool negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);
    ulong n = scaleNumerator;
    ulong d = scaleDenominator;

    // Cross-cancel factors across the rational numerator/denominator before
    // either multiplication. Internal cancellation within a*n or b*d cannot
    // change the represented rational value.
    ulong g = gcd(a, b);
    a /= g;
    b /= g;

    g = gcd(a, d);
    a /= g;
    d /= g;

    g = gcd(n, b);
    n /= g;
    b /= g;

    g = gcd(n, d);
    n /= g;
    d /= g;

    ulong numerator;
    ulong denominator;

    if (!checkedMul(a, n, numerator))
        return Result(QuotientStatus.overflow, false, 0);
    if (!checkedMul(b, d, denominator))
        return Result(QuotientStatus.overflow, false, 0);

    // denominator cannot be zero because all original factors were nonzero.
    if (numerator % denominator != 0)
        return Result(QuotientStatus.inexact, false, 0);

    return Result(
        QuotientStatus.exact,
        negative,
        numerator / denominator);
}

private long signedValue(Result r) @safe pure nothrow @nogc
{
    assert(r.status == QuotientStatus.exact);

    if (!r.negative)
    {
        assert(r.magnitude <= cast(ulong)long.max);
        return cast(long)r.magnitude;
    }

    if (r.magnitude == cast(ulong)long.max + 1UL)
        return long.min;

    assert(r.magnitude <= cast(ulong)long.max);
    return -cast(long)r.magnitude;
}

@safe pure nothrow @nogc
long ctfeProbe()
{
    auto r = exactScaledQuotient(1000, 2, 1, 1000);
    assert(r.status == QuotientStatus.inexact);

    r = exactScaledQuotient(2000, 2, 1, 1000);
    assert(r.status == QuotientStatus.exact);
    return signedValue(r);
}

enum ctfe = ctfeProbe();
static assert(ctfe == 1);

// Basic exact / inexact / zero.
static assert(exactScaledQuotient(6, 3, 1, 1).status ==
    QuotientStatus.exact);
static assert(exactScaledQuotient(5, 2, 1, 1).status ==
    QuotientStatus.inexact);
static assert(exactScaledQuotient(5, 0, 1, 1).status ==
    QuotientStatus.divisionByZero);

// Signs and extrema.
static assert(signedValue(
    exactScaledQuotient(-6, 3, 1, 1)) == -2);
static assert(signedValue(
    exactScaledQuotient(6, -3, 1, 1)) == -2);
static assert(signedValue(
    exactScaledQuotient(-6, -3, 1, 1)) == 2);
static assert(signedValue(
    exactScaledQuotient(long.min, 1, 1, 1)) == long.min);

// long.min / -1 is mathematically +2^63. The magnitude kernel can represent
// it even though signed long cannot. Rep selection must decide whether a
// public operation can admit this case.
static assert(
    exactScaledQuotient(long.min, -1, 1, 1).status ==
        QuotientStatus.exact);
static assert(
    exactScaledQuotient(long.min, -1, 1, 1).magnitude ==
        cast(ulong)long.max + 1UL);

// Cross-cancellation avoids overflow:
// (long.max * 2) / (2 * 1) == long.max.
static assert(signedValue(
    exactScaledQuotient(long.max, 2, 2, 1)) == long.max);

// Scale denominator can cancel the lhs before multiplication:
// (long.max * long.max) / (1 * long.max) == long.max.
static assert(signedValue(
    exactScaledQuotient(
        long.max,
        1,
        cast(ulong)long.max,
        cast(ulong)long.max)) == long.max);

// km/h -> m/s rescale 5/18.
// 36 km/h / 1 quantity-unit => 10 canonical m/s.
static assert(signedValue(
    exactScaledQuotient(36, 1, 5, 18)) == 10);

// m/km -> canonical ratio rescale 1/1000.
static assert(signedValue(
    exactScaledQuotient(2000, 2, 1, 1000)) == 1);
static assert(
    exactScaledQuotient(1000, 2, 1, 1000).status ==
        QuotientStatus.inexact);

// A genuine bounded-intermediate overflow remains possible in this ulong
// oracle when no cancellation exists.
static assert(
    exactScaledQuotient(long.max, 1, cast(ulong)long.max, 1).status ==
        QuotientStatus.overflow);

void main() {}
