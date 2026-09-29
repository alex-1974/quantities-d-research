module static_scale_23d;

import core.checkedint : mulu;

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
    const bits = cast(ulong) value;
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
 * Probe 23c reference.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticC(
    ulong Numerator,
    ulong Denominator)(
    long lhs,
    long rhs)
{
    static assert(Denominator != 0);
    static assert(gcd(Numerator, Denominator) == 1);

    const negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);

    enum ulong n = Numerator;

    static if (Denominator != 1)
    {
        ulong d = Denominator;

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
        negative ? signMagnitude : cast(ulong) long.max;

    ulong product = 1;

    foreach (factor; [a, b, n])
    {
        if (factor == 0)
        {
            product = 0;
            break;
        }

        if (product > limit / factor)
            return RescaleResult(
                0,
                RescaleStatus.overflow);

        product *= factor;
    }

    if (negative)
    {
        if (product == signMagnitude)
            return RescaleResult(
                long.min,
                RescaleStatus.exact);

        return RescaleResult(
            -cast(long) product,
            RescaleStatus.exact);
    }

    return RescaleResult(
        cast(long) product,
        RescaleStatus.exact);
}


/*
 * Probe 23d candidate.
 *
 * Cancellation semantics are identical to 23c.
 *
 * Difference:
 * final magnitude multiplication uses core.checkedint.mulu
 * instead of division-based prechecking.
 *
 * mulu detects ulong overflow. A second comparison against the
 * signed-result magnitude limit handles the narrower positive
 * long range.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticD(
    ulong Numerator,
    ulong Denominator)(
    long lhs,
    long rhs)
{
    static assert(Denominator != 0);
    static assert(gcd(Numerator, Denominator) == 1);

    const negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);

    enum ulong n = Numerator;

    static if (Denominator != 1)
    {
        ulong d = Denominator;

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
        negative ? signMagnitude : cast(ulong) long.max;

    ulong product = 1;
    bool overflow = false;

    foreach (factor; [a, b, n])
    {
        product = mulu(
            product,
            factor,
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
            -cast(long) product,
            RescaleStatus.exact);
    }

    return RescaleResult(
        cast(long) product,
        RescaleStatus.exact);
}


/*
 * Codegen entry points.
 */

extern(C)
RescaleResult r04_23d_static_1_1(long lhs, long rhs)
{
    return checkedRescaleStaticD!(1, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23d_static_1_2(long lhs, long rhs)
{
    return checkedRescaleStaticD!(1, 2)(lhs, rhs);
}

extern(C)
RescaleResult r04_23d_static_2_1(long lhs, long rhs)
{
    return checkedRescaleStaticD!(2, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23d_static_7_15(long lhs, long rhs)
{
    return checkedRescaleStaticD!(7, 15)(lhs, rhs);
}


/*
 * Differential semantic oracle: 23d must produce exactly
 * the same observable result as 23c.
 */

@safe pure nothrow @nogc
bool sameResult(
    RescaleResult a,
    RescaleResult b)
{
    return a.status == b.status &&
           a.value == b.value;
}

@safe pure nothrow @nogc
bool differentialProbe()
{
    enum long[] values = [
        long.min,
        long.min + 1,
        -100,
        -15,
        -10,
        -7,
        -6,
        -5,
        -3,
        -2,
        -1,
        0,
        1,
        2,
        3,
        5,
        6,
        7,
        10,
        15,
        100,
        long.max - 1,
        long.max
    ];

    foreach (lhs; values)
    {
        foreach (rhs; values)
        {
            if (!sameResult(
                    checkedRescaleStaticC!(1, 1)(
                        lhs,
                        rhs),
                    checkedRescaleStaticD!(1, 1)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticC!(1, 2)(
                        lhs,
                        rhs),
                    checkedRescaleStaticD!(1, 2)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticC!(2, 1)(
                        lhs,
                        rhs),
                    checkedRescaleStaticD!(2, 1)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticC!(7, 15)(
                        lhs,
                        rhs),
                    checkedRescaleStaticD!(7, 15)(
                        lhs,
                        rhs)))
                return false;
        }
    }

    return true;
}

static assert(differentialProbe());

void main()
{
    assert(differentialProbe());
}
