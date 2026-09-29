module static_scale_23h;

import core.checkedint : mulu;
import std.stdio : writeln;

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
 * R04.23h-C
 *
 * Signed normalized scale:
 *
 *     Numerator / Denominator
 *
 * Contract:
 * - Denominator > 0
 * - ratio already normalized
 * - Numerator may be negative, zero, long.min, long.max
 * - zero numerator is exact zero without evaluating lhs*rhs
 *
 * Overflow proof uses division bounds.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleSignedC(
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

    /*
     * Critical semantic case:
     *
     * (lhs * rhs * 0) / 1 == 0
     *
     * Do not inspect whether lhs*rhs would overflow.
     */
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
            ulong d =
                cast(ulong)Denominator;

            auto g = gcd(a, d);
            a /= g;
            d /= g;

            g = gcd(b, d);
            b /= g;
            d /= g;

            /*
             * Because the ratio is normalized:
             *
             * gcd(|Numerator|, Denominator) == 1
             *
             * therefore any denominator remaining after
             * cancellation against lhs and rhs cannot be
             * cancelled by Numerator.
             */
            if (d != 1)
                return RescaleResult(
                    0,
                    RescaleStatus.inexact);
        }

        enum ulong signMagnitude =
            1UL << 63;

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
 * R04.23h-D
 *
 * Identical semantics, but checked multiplication uses
 * core.checkedint.mulu. This remains the candidate for
 * the LDC-specialized backend.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleSignedD(
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
            ulong d =
                cast(ulong)Denominator;

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

        enum ulong signMagnitude =
            1UL << 63;

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


@safe pure nothrow @nogc
bool same(
    RescaleResult a,
    RescaleResult b)
{
    return
        a.value == b.value &&
        a.status == b.status;
}


/*
 * Exact expected cases.
 */
static assert(
    same(
        checkedRescaleSignedC!(0, 1)(
            long.max,
            long.max),
        RescaleResult(
            0,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedD!(0, 1)(
            long.max,
            long.max),
        RescaleResult(
            0,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(-1, 1)(2, 3),
        RescaleResult(
            -6,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(-1, 1)(-2, 3),
        RescaleResult(
            6,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(-1, 1)(-2, -3),
        RescaleResult(
            -6,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(1, 1)(
            long.min,
            1),
        RescaleResult(
            long.min,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(-1, 1)(
            long.min,
            -1),
        RescaleResult(
            long.min,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(1, 2)(
            long.max,
            2),
        RescaleResult(
            long.max,
            RescaleStatus.exact)));

static assert(
    same(
        checkedRescaleSignedC!(-1, 2)(
            long.max,
            2),
        RescaleResult(
            -long.max,
            RescaleStatus.exact)));


/*
 * Inexactness after cancellation.
 */
static assert(
    checkedRescaleSignedC!(1, 2)(
        3,
        3).status ==
        RescaleStatus.inexact);

static assert(
    checkedRescaleSignedC!(-1, 2)(
        3,
        3).status ==
        RescaleStatus.inexact);


/*
 * Overflow boundaries.
 */
static assert(
    checkedRescaleSignedC!(1, 1)(
        long.max,
        2).status ==
        RescaleStatus.overflow);

static assert(
    checkedRescaleSignedC!(-1, 1)(
        long.max,
        2).status ==
        RescaleStatus.overflow);

static assert(
    checkedRescaleSignedC!(2, 1)(
        long.max,
        1).status ==
        RescaleStatus.overflow);


/*
 * Numerator == long.min must not overflow while obtaining
 * its magnitude.
 */
static assert(
    checkedRescaleSignedC!(
        long.min,
        1)(
        1,
        1) ==
        RescaleResult(
            long.min,
            RescaleStatus.exact));

static assert(
    checkedRescaleSignedD!(
        long.min,
        1)(
        1,
        1) ==
        RescaleResult(
            long.min,
            RescaleStatus.exact));


/*
 * C and D must agree over adversarial values and signed scales.
 */
enum long[] values =
[
    long.min,
    long.min + 1,
    -4,
    -3,
    -2,
    -1,
    0,
    1,
    2,
    3,
    4,
    long.max - 1,
    long.max
];

@safe pure nothrow @nogc
bool differential()
{
    foreach (a; values)
    {
        foreach (b; values)
        {
            if (!same(
                    checkedRescaleSignedC!(0, 1)(a, b),
                    checkedRescaleSignedD!(0, 1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(1, 1)(a, b),
                    checkedRescaleSignedD!(1, 1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(-1, 1)(a, b),
                    checkedRescaleSignedD!(-1, 1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(1, 2)(a, b),
                    checkedRescaleSignedD!(1, 2)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(-1, 2)(a, b),
                    checkedRescaleSignedD!(-1, 2)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(2, 1)(a, b),
                    checkedRescaleSignedD!(2, 1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(-2, 1)(a, b),
                    checkedRescaleSignedD!(-2, 1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(7, 15)(a, b),
                    checkedRescaleSignedD!(7, 15)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(-7, 15)(a, b),
                    checkedRescaleSignedD!(-7, 15)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(
                        long.max,
                        1)(a, b),
                    checkedRescaleSignedD!(
                        long.max,
                        1)(a, b)))
                return false;

            if (!same(
                    checkedRescaleSignedC!(
                        long.min,
                        1)(a, b),
                    checkedRescaleSignedD!(
                        long.min,
                        1)(a, b)))
                return false;
        }
    }

    return true;
}

static assert(differential());


void main()
{
    assert(differential());

    writeln(
        "R04.23h PASS: signed/zero normalized-ratio kernel");

    writeln(
        "zero: ",
        checkedRescaleSignedC!(0, 1)(
            long.max,
            long.max));

    writeln(
        "negative scale: ",
        checkedRescaleSignedC!(-1, 1)(
            2,
            3));

    writeln(
        "long.min numerator: ",
        checkedRescaleSignedC!(
            long.min,
            1)(
            1,
            1));
}
