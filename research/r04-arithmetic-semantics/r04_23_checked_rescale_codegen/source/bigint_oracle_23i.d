module bigint_oracle_23i;

import core.checkedint : mulu;
import std.bigint : BigInt;
import std.stdio : writefln, writeln;

enum RescaleStatus : ubyte
{
    exact,
    inexact,
    overflow
}

struct RescaleResult
{
    long value;
    RescaleStatus status;
}

@safe pure nothrow @nogc
ulong magnitude(long value)
{
    const bits = cast(ulong)value;
    return value < 0 ? 0UL - bits : bits;
}

@safe pure nothrow @nogc
ulong gcd(ulong a, ulong b)
{
    while (b != 0)
    {
        const r = a % b;
        a = b;
        b = r;
    }

    return a;
}


/*
 * Candidate C:
 * portable division-bound checked multiplication.
 */
@safe pure nothrow @nogc
RescaleResult candidateC(
    long Numerator,
    long Denominator)(
    long lhs,
    long rhs)
{
    static assert(Denominator > 0);
    static assert(
        gcd(
            magnitude(Numerator),
            cast(ulong)Denominator) == 1);

    static if (Numerator == 0)
    {
        return RescaleResult(
            0,
            RescaleStatus.exact);
    }
    else
    {
        const negative =
            ((lhs < 0) != (rhs < 0))
            != (Numerator < 0);

        ulong a = magnitude(lhs);
        ulong b = magnitude(rhs);

        enum ulong numeratorMagnitude =
            magnitude(Numerator);

        static if (Denominator != 1)
        {
            ulong d = cast(ulong)Denominator;

            auto g = gcd(a, d);
            a /= g;
            d /= g;

            g = gcd(b, d);
            b /= g;
            d /= g;

            if (d != 1)
                return RescaleResult(
                    0,
                    RescaleStatus.inexact);
        }

        enum ulong signMagnitude = 1UL << 63;

        const limit =
            negative
                ? signMagnitude
                : cast(ulong)long.max;

        ulong product;

        if (b == 0)
        {
            product = 0;
        }
        else
        {
            if (a > limit / b)
                return RescaleResult(
                    0,
                    RescaleStatus.overflow);

            product = a * b;
        }

        static if (numeratorMagnitude != 1)
        {
            if (product >
                limit / numeratorMagnitude)
            {
                return RescaleResult(
                    0,
                    RescaleStatus.overflow);
            }

            product *= numeratorMagnitude;
        }

        if (negative)
        {
            if (product == signMagnitude)
                return RescaleResult(
                    long.min,
                    RescaleStatus.exact);

            return RescaleResult(
                -cast(long)product,
                RescaleStatus.exact);
        }

        return RescaleResult(
            cast(long)product,
            RescaleStatus.exact);
    }
}


/*
 * Candidate D:
 * core.checkedint.mulu checked multiplication.
 */
@safe pure nothrow @nogc
RescaleResult candidateD(
    long Numerator,
    long Denominator)(
    long lhs,
    long rhs)
{
    static assert(Denominator > 0);
    static assert(
        gcd(
            magnitude(Numerator),
            cast(ulong)Denominator) == 1);

    static if (Numerator == 0)
    {
        return RescaleResult(
            0,
            RescaleStatus.exact);
    }
    else
    {
        const negative =
            ((lhs < 0) != (rhs < 0))
            != (Numerator < 0);

        ulong a = magnitude(lhs);
        ulong b = magnitude(rhs);

        enum ulong numeratorMagnitude =
            magnitude(Numerator);

        static if (Denominator != 1)
        {
            ulong d = cast(ulong)Denominator;

            auto g = gcd(a, d);
            a /= g;
            d /= g;

            g = gcd(b, d);
            b /= g;
            d /= g;

            if (d != 1)
                return RescaleResult(
                    0,
                    RescaleStatus.inexact);
        }

        enum ulong signMagnitude = 1UL << 63;

        const limit =
            negative
                ? signMagnitude
                : cast(ulong)long.max;

        bool overflow = false;

        ulong product =
            mulu(a, b, overflow);

        if (overflow || product > limit)
            return RescaleResult(
                0,
                RescaleStatus.overflow);

        static if (numeratorMagnitude != 1)
        {
            overflow = false;

            product =
                mulu(
                    product,
                    numeratorMagnitude,
                    overflow);

            if (overflow || product > limit)
                return RescaleResult(
                    0,
                    RescaleStatus.overflow);
        }

        if (negative)
        {
            if (product == signMagnitude)
                return RescaleResult(
                    long.min,
                    RescaleStatus.exact);

            return RescaleResult(
                -cast(long)product,
                RescaleStatus.exact);
        }

        return RescaleResult(
            cast(long)product,
            RescaleStatus.exact);
    }
}


/*
 * Independent oracle.
 *
 * Deliberately does NOT:
 * - use magnitude arithmetic
 * - use gcd cancellation
 * - use checked multiplication
 * - share the candidate algorithm
 *
 * It computes the mathematical expression directly using BigInt.
 */
RescaleResult oracle(
    long lhs,
    long rhs,
    long numerator,
    long denominator)
{
    assert(denominator > 0);

    BigInt product = BigInt(lhs);
    product *= BigInt(rhs);
    product *= BigInt(numerator);

    const divisor = BigInt(denominator);

    if ((product % divisor) != BigInt(0))
    {
        return RescaleResult(
            0,
            RescaleStatus.inexact);
    }

    const result = product / divisor;

    const minimum = BigInt(long.min);
    const maximum = BigInt(long.max);

    if (result < minimum || result > maximum)
    {
        return RescaleResult(
            0,
            RescaleStatus.overflow);
    }

    return RescaleResult(
        result.toLong(),
        RescaleStatus.exact);
}


bool same(
    RescaleResult lhs,
    RescaleResult rhs)
{
    return
        lhs.value == rhs.value &&
        lhs.status == rhs.status;
}


enum long[] values =
[
    long.min,
    long.min + 1,
    -(1L << 62),
    -1_000_000_000,
    -65_536,
    -257,
    -16,
    -7,
    -4,
    -3,
    -2,
    -1,
    0,
    1,
    2,
    3,
    4,
    7,
    16,
    257,
    65_536,
    1_000_000_000,
    1L << 62,
    long.max - 1,
    long.max
];


size_t comparisons;


void check(
    long Numerator,
    long Denominator)(
    long lhs,
    long rhs,
    string label)
{
    const expected =
        oracle(
            lhs,
            rhs,
            Numerator,
            Denominator);

    const c =
        candidateC!(
            Numerator,
            Denominator)(
            lhs,
            rhs);

    const d =
        candidateD!(
            Numerator,
            Denominator)(
            lhs,
            rhs);

    ++comparisons;

    if (!same(c, expected) ||
        !same(d, expected))
    {
        writefln(
            "FAIL %s N=%s D=%s lhs=%s rhs=%s",
            label,
            Numerator,
            Denominator,
            lhs,
            rhs);

        writefln(
            "oracle: value=%s status=%s",
            expected.value,
            expected.status);

        writefln(
            "C:      value=%s status=%s",
            c.value,
            c.status);

        writefln(
            "D:      value=%s status=%s",
            d.value,
            d.status);

        assert(0);
    }
}


void runRatio(
    long Numerator,
    long Denominator)(
    string label)
{
    foreach (lhs; values)
    {
        foreach (rhs; values)
        {
            check!(
                Numerator,
                Denominator)(
                lhs,
                rhs,
                label);
        }
    }
}


void main()
{
    /*
     * Zero.
     */
    runRatio!(0, 1)("0/1");

    /*
     * Unit scales and sign.
     */
    runRatio!(1, 1)("1/1");
    runRatio!(-1, 1)("-1/1");

    /*
     * Cancellation / inexactness.
     */
    runRatio!(1, 2)("1/2");
    runRatio!(-1, 2)("-1/2");

    /*
     * Numerator multiplication.
     */
    runRatio!(2, 1)("2/1");
    runRatio!(-2, 1)("-2/1");

    /*
     * General normalized rational.
     */
    runRatio!(7, 15)("7/15");
    runRatio!(-7, 15)("-7/15");

    /*
     * Numerator boundaries.
     */
    runRatio!(long.max, 1)("long.max/1");
    runRatio!(-long.max, 1)("-long.max/1");
    runRatio!(long.min, 1)("long.min/1");

    /*
     * Denominator boundary.
     */
    runRatio!(1, long.max)("1/long.max");
    runRatio!(-1, long.max)("-1/long.max");

    /*
     * Large normalized ratios near unity.
     */
    runRatio!(
        long.max - 1,
        long.max)(
        "(long.max-1)/long.max");

    runRatio!(
        -(long.max - 1),
        long.max)(
        "-(long.max-1)/long.max");

    /*
     * Explicit cases important to R04.14.
     */

    // Intermediate product would overflow, final result exact.
    check!(1, 2)(
        long.max,
        2,
        "cancel-before-overflow");

    // Zero numerator suppresses any intermediate overflow.
    check!(0, 1)(
        long.max,
        long.max,
        "zero-suppresses-overflow");

    // Exact long.min boundary.
    check!(long.min, 1)(
        1,
        1,
        "numerator-long.min");

    check!(-1, 1)(
        long.min,
        -1,
        "negative-scale-long.min");

    writeln(
        "R04.23i PASS: BigInt oracle agrees with C and D");

    writefln(
        "oracle comparisons: %s",
        comparisons);
}
