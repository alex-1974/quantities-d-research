module r04_13_exact_quotient_result_bound_probe;

// R04.13 probe 7: bound the final magnitude of exact integral quotients.
//
// For |lhs| = A, |rhs| >= 1 and fixed positive reduced scale n/d:
//
//     result = A * n / (|rhs| * d)
//
// An exact integer result cannot exceed floor(A*n/d), and choosing |rhs|=1
// reaches that upper envelope whenever divisibility permits. We must compute
// floor(A*n/d) without overflowing A*n.

struct U128
{
    ulong hi;
    ulong lo;
}

private U128 multiply64(ulong a, ulong b) @safe pure nothrow @nogc
{
    enum ulong mask = 0xffff_ffffUL;

    const ulong a0 = a & mask;
    const ulong a1 = a >> 32;
    const ulong b0 = b & mask;
    const ulong b1 = b >> 32;

    const ulong p00 = a0 * b0;
    const ulong p01 = a0 * b1;
    const ulong p10 = a1 * b0;
    const ulong p11 = a1 * b1;

    const ulong middle =
        (p00 >> 32) +
        (p01 & mask) +
        (p10 & mask);

    U128 r;
    r.lo = (p00 & mask) | (middle << 32);
    r.hi = p11 + (p01 >> 32) + (p10 >> 32) + (middle >> 32);
    return r;
}

private int compare(U128 a, U128 b) @safe pure nothrow @nogc
{
    if (a.hi < b.hi) return -1;
    if (a.hi > b.hi) return 1;
    if (a.lo < b.lo) return -1;
    if (a.lo > b.lo) return 1;
    return 0;
}

// Is A*n <= Limit*d? This comparison avoids division and all 64-bit product
// overflow by comparing exact 128-bit products.
private bool scaledBoundFits(
    ulong a,
    ulong n,
    ulong d,
    ulong limit) @safe pure nothrow @nogc
{
    assert(d != 0);
    return compare(multiply64(a, n), multiply64(limit, d)) <= 0;
}

// This predicate is deliberately conservative for the complete mathematical
// quotient envelope. If true, every exact result magnitude fits Limit.
// It does not require constructing floor(A*n/d).
private bool allExactResultsFit(
    ulong lhsMaxMagnitude,
    ulong scaleNumerator,
    ulong scaleDenominator,
    ulong resultLimit) @safe pure nothrow @nogc
{
    return scaledBoundFits(
        lhsMaxMagnitude,
        scaleNumerator,
        scaleDenominator,
        resultLimit);
}

enum signedBytePositive = cast(ulong)byte.max;       // 127
enum signedByteMagnitude = cast(ulong)(-byte.min);   // 128
enum signedShortPositive = cast(ulong)short.max;
enum signedShortMagnitude = cast(ulong)(-short.min);
enum signedIntPositive = cast(ulong)int.max;
enum signedIntMagnitude = cast(ulong)(-(cast(long)int.min));
enum signedLongPositive = cast(ulong)long.max;
enum signedLongMagnitude = cast(ulong)long.max + 1UL;

// Unit scale.
static assert(allExactResultsFit(
    signedIntMagnitude, 1, 1, cast(ulong)long.max));

// int.min / -1 requires +2^31, so int itself is not a sufficient signed
// result domain even though long is.
static assert(!allExactResultsFit(
    signedIntMagnitude, 1, 1, cast(ulong)int.max));
static assert(allExactResultsFit(
    signedIntMagnitude, 1, 1, cast(ulong)long.max));

// long operands have no wider built-in signed integer. +2^63 is a witness.
static assert(!allExactResultsFit(
    signedLongMagnitude, 1, 1, signedLongPositive));

// Rational scale can reduce the complete result envelope.
// int magnitude * 1/1000 easily fits int.
static assert(allExactResultsFit(
    signedIntMagnitude, 1, 1000, cast(ulong)int.max));

// Rational scale can also enlarge it.
// byte magnitude * 1000 exceeds short but fits int.
static assert(!allExactResultsFit(
    signedByteMagnitude, 1000, 1, cast(ulong)short.max));
static assert(allExactResultsFit(
    signedByteMagnitude, 1000, 1, cast(ulong)int.max));

// 5/18 (km/h -> m/s) reduces the envelope.
static assert(allExactResultsFit(
    signedIntMagnitude, 5, 18, cast(ulong)int.max));

// Exact 128-bit comparison handles products that overflow ulong.
static assert(allExactResultsFit(
    cast(ulong)long.max,
    cast(ulong)long.max,
    cast(ulong)long.max,
    cast(ulong)long.max));

// If scale numerator is huge and denominator cannot compensate, the bound
// correctly rejects a signed-long result domain without forming the product.
static assert(!allExactResultsFit(
    cast(ulong)long.max,
    cast(ulong)long.max,
    1,
    cast(ulong)long.max));

// Key limitation of a magnitude-only envelope:
// signed result domains have asymmetric positive/negative limits. Whether the
// + or - envelope is reachable depends on operand signedness and signs.
// Production ResultRep selection therefore needs separate positive and
// negative bounds, as the product range algebra already does.

@safe pure nothrow @nogc
bool ctfeProbe()
{
    return allExactResultsFit(
        signedShortMagnitude, 5, 18, cast(ulong)short.max);
}

enum ctfe = ctfeProbe();
static assert(ctfe);

void main() {}
