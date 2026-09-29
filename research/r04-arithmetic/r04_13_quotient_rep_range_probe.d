module r04_13_quotient_rep_range_probe;

import std.traits : isIntegral, isSigned;

// R04.13 probe 5: separate result-range admissibility from intermediate-range
// admissibility for exact scaled Quantity/Quantity division.

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

// Existing scalar-division-style quotient Rep rule: signed divisors can require
// one wider signed type to make cases such as int.min / -1 representable.
template ScalarQuotientRep(A, B)
{
    static assert(isIntegral!A && isIntegral!B);

    static if (!isSigned!B)
        alias ScalarQuotientRep = A;
    else static if (A.sizeof < long.sizeof)
    {
        static if (A.sizeof == 1)
            alias ScalarQuotientRep = short;
        else static if (A.sizeof == 2)
            alias ScalarQuotientRep = int;
        else
            alias ScalarQuotientRep = long;
    }
    else
        alias ScalarQuotientRep = void;
}

static assert(is(ScalarQuotientRep!(int, int) == long));
static assert(is(ScalarQuotientRep!(long, long) == void));

// A scaled Quantity/Quantity quotient has an additional exact rational factor.
// Even when the final quotient is tiny, an eager bounded intermediate can be
// much larger than the result.

struct ReducedFactors
{
    ulong lhs;
    ulong rhs;
    ulong scaleNumerator;
    ulong scaleDenominator;
}

ReducedFactors reduce(
    ulong lhs,
    ulong rhs,
    ulong scaleNumerator,
    ulong scaleDenominator) @safe pure nothrow @nogc
{
    ulong g = gcd(lhs, rhs);
    lhs /= g;
    rhs /= g;

    g = gcd(lhs, scaleDenominator);
    lhs /= g;
    scaleDenominator /= g;

    g = gcd(scaleNumerator, rhs);
    scaleNumerator /= g;
    rhs /= g;

    g = gcd(scaleNumerator, scaleDenominator);
    scaleNumerator /= g;
    scaleDenominator /= g;

    return ReducedFactors(lhs, rhs, scaleNumerator, scaleDenominator);
}

// Final exact integer result can fit long although an eager numerator product
// does not fit long. Cross-cancellation is therefore semantically relevant to
// range analysis, not merely an optimization.
enum cancelled = reduce(
    cast(ulong)long.max,
    2,
    2,
    1);
static assert(cancelled.lhs == cast(ulong)long.max);
static assert(cancelled.scaleNumerator == 1);
static assert(cancelled.rhs == 1);

// Conversely, no amount of cross-cancellation helps if the exact reduced
// numerator itself exceeds the available bounded intermediate domain.
enum uncancelled = reduce(
    cast(ulong)long.max,
    1,
    cast(ulong)long.max,
    1);
static assert(uncancelled.lhs == cast(ulong)long.max);
static assert(uncancelled.scaleNumerator == cast(ulong)long.max);

// Result range and intermediate range are not the same question. A quotient
// may have a representable final value only for some runtime operand values,
// while the complete Rep domain admits much larger exact rational numerators.
//
// Example family:
//   (lhs * K) / rhs
// For lhs=rhs the result is K, but rhs may also be 1. A total compile-time
// proof over complete operand Reps must account for that worst case.

// Zero is always representable by built-in integral divisor Reps. Therefore
// no integral Quantity/Quantity division can be total over the complete RHS
// Rep domain unless the API excludes zero through a stronger divisor type.
enum integralDirectDivisionTotal = false;
static assert(!integralDirectDivisionTotal);

// A named checked/exact operation may remain available with runtime statuses.
// Its result Rep can be selected independently from its intermediate strategy.
// The current research does not yet prove a smallest built-in ResultRep for
// every (LhsRep,RhsRep,scale) tuple.

// Magnitude 2^63 is a useful boundary witness: mathematically exact and
// representable in ulong, but not in signed long.
enum minOverMinusOneMagnitude = magnitude(long.min);
static assert(minOverMinusOneMagnitude == cast(ulong)long.max + 1UL);
static assert(minOverMinusOneMagnitude > cast(ulong)long.max);

// A compile-time total-range gate cannot make divisionByZero unreachable for
// ordinary integral RHS Reps. That differs fundamentally from multiplication.
// Overflow may potentially be removed only if a future exact intermediate
// strategy plus ResultRep proof establishes it independently.

void main() {}
