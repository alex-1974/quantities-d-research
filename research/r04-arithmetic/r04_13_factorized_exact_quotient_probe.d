module r04_13_factorized_exact_quotient_probe;

// R04.13 probe 6: can exact integral Quantity/Quantity division avoid
// intermediate overflow by deciding exactness from fully reduced factors first?

enum Status : ubyte
{
    exact,
    inexact,
    divisionByZero,
    resultOutOfRange
}

struct Result
{
    Status status;
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

private void cancel(ref ulong numerator, ref ulong denominator)
    @safe pure nothrow @nogc
{
    const g = gcd(numerator, denominator);
    numerator /= g;
    denominator /= g;
}

Result factorizedExactQuotient(
    long lhs,
    long rhs,
    ulong scaleNumerator,
    ulong scaleDenominator,
    ulong positiveResultMax,
    ulong negativeResultMax) @safe pure nothrow @nogc
{
    assert(scaleNumerator != 0);
    assert(scaleDenominator != 0);

    if (rhs == 0)
        return Result(Status.divisionByZero, false, 0);

    if (lhs == 0)
        return Result(Status.exact, false, 0);

    const negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);
    ulong n = scaleNumerator;
    ulong d = scaleDenominator;

    // Fully reduce every numerator factor against every denominator factor.
    cancel(a, b);
    cancel(a, d);
    cancel(n, b);
    cancel(n, d);

    // After complete pairwise cancellation, an exact integral result requires
    // the entire denominator product to be one. We never need to form b*d.
    if (b != 1 || d != 1)
        return Result(Status.inexact, false, 0);

    // The exact result is now a*n. Avoid forming it until its fit in the
    // selected result representation has been proven.
    const limit = negative ? negativeResultMax : positiveResultMax;

    if (a != 0 && n > limit / a)
        return Result(Status.resultOutOfRange, false, 0);

    return Result(Status.exact, negative, a * n);
}

// Signed-long result limits expressed as magnitudes.
enum signedLongPositiveMax = cast(ulong)long.max;
enum signedLongNegativeMax = cast(ulong)long.max + 1UL;

// Basic behavior.
static assert(factorizedExactQuotient(
    6, 3, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).status == Status.exact);

static assert(factorizedExactQuotient(
    5, 2, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).status == Status.inexact);

static assert(factorizedExactQuotient(
    5, 0, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).status ==
    Status.divisionByZero);

// Exactness can be decided without multiplying denominator factors.
static assert(factorizedExactQuotient(
    1, long.max, 1, cast(ulong)long.max,
    signedLongPositiveMax, signedLongNegativeMax).status == Status.inexact);

// Cross-cancellation can eliminate huge apparent intermediates.
static assert(factorizedExactQuotient(
    long.max, 1,
    cast(ulong)long.max, cast(ulong)long.max,
    signedLongPositiveMax, signedLongNegativeMax).magnitude ==
    cast(ulong)long.max);

// 36 * 5 / 18 == 10, the km/h -> m/s scale witness.
static assert(factorizedExactQuotient(
    36, 1, 5, 18,
    signedLongPositiveMax, signedLongNegativeMax).magnitude == 10);

// 1000 / (2 * 1000) is not integral.
static assert(factorizedExactQuotient(
    1000, 2, 1, 1000,
    signedLongPositiveMax, signedLongNegativeMax).status == Status.inexact);

// 2000 / (2 * 1000) == 1.
static assert(factorizedExactQuotient(
    2000, 2, 1, 1000,
    signedLongPositiveMax, signedLongNegativeMax).magnitude == 1);

// long.min / 1 is valid in signed long.
static assert(factorizedExactQuotient(
    long.min, 1, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).status == Status.exact);
static assert(factorizedExactQuotient(
    long.min, 1, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).magnitude ==
    signedLongNegativeMax);

// long.min / -1 is mathematically exact but outside signed long.
static assert(factorizedExactQuotient(
    long.min, -1, 1, 1,
    signedLongPositiveMax, signedLongNegativeMax).status ==
    Status.resultOutOfRange);

// If the selected result representation can contain +2^63, the same
// mathematical operation no longer has an arithmetic-intermediate problem.
static assert(factorizedExactQuotient(
    long.min, -1, 1, 1,
    ulong.max, ulong.max).status == Status.exact);

// A non-cancellable scale can make the final exact result too large, but that
// is a result-range failure, not intermediate overflow.
static assert(factorizedExactQuotient(
    long.max, 1, cast(ulong)long.max, 1,
    signedLongPositiveMax, signedLongNegativeMax).status ==
    Status.resultOutOfRange);

@safe pure nothrow @nogc
ulong ctfeProbe()
{
    auto r = factorizedExactQuotient(
        72, 2, 5, 18,
        signedLongPositiveMax, signedLongNegativeMax);
    assert(r.status == Status.exact);
    return r.magnitude;
}

enum ctfe = ctfeProbe();
static assert(ctfe == 10);

void main() {}
