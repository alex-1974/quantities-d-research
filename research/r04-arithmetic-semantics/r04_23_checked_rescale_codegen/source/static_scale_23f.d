module static_scale_23f;

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
 * 23f-C:
 *
 * Structural specialization of 23c.
 *
 * - denominator cancellation remains unchanged
 * - product starts at a, not 1
 * - only a*b requires a runtime checked multiplication
 * - multiplication by Numerator exists only when Numerator != 1
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticFC(
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
        negative
            ? signMagnitude
            : cast(ulong) long.max;

    /*
     * First real product: a*b.
     *
     * b == 0 is special because limit / b would be invalid.
     */
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

    /*
     * Numerator is a compile-time constant.
     * Multiplication by one must not exist in generated code.
     */
    static if (Numerator != 1)
    {
        static if (Numerator == 0)
        {
            product = 0;
        }
        else
        {
            if (product > limit / Numerator)
                return RescaleResult(
                    0,
                    RescaleStatus.overflow);

            product *= Numerator;
        }
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
 * 23f-D:
 *
 * Same structural specialization, using core.checkedint.mulu.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticFD(
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
        negative
            ? signMagnitude
            : cast(ulong) long.max;

    bool overflow = false;

    ulong product =
        mulu(a, b, overflow);

    if (overflow || product > limit)
        return RescaleResult(
            0,
            RescaleStatus.overflow);

    static if (Numerator != 1)
    {
        static if (Numerator == 0)
        {
            product = 0;
        }
        else
        {
            overflow = false;

            product =
                mulu(
                    product,
                    Numerator,
                    overflow);

            if (overflow || product > limit)
                return RescaleResult(
                    0,
                    RescaleStatus.overflow);
        }
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
 * Independent mathematical reference retained from 23c.
 */
@safe pure nothrow @nogc
RescaleResult referenceRescale(
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
        negative
            ? signMagnitude
            : cast(ulong) long.max;

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


@safe pure nothrow @nogc
bool sameResult(
    RescaleResult a,
    RescaleResult b)
{
    return
        a.value == b.value &&
        a.status == b.status;
}


/*
 * Differential CTFE oracle.
 */
@safe pure nothrow @nogc
bool differentialProbe()
{
    enum long[] values = [
        long.min,
        long.min + 1,
        -100,
        -30,
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
        30,
        100,
        long.max - 1,
        long.max
    ];

    foreach (lhs; values)
    {
        foreach (rhs; values)
        {
            foreach (dummy; 0 .. 1)
            {
                auto r11 =
                    referenceRescale!(1, 1)(
                        lhs,
                        rhs);

                if (!sameResult(
                        r11,
                        checkedRescaleStaticFC!(1, 1)(
                            lhs,
                            rhs)))
                    return false;

                if (!sameResult(
                        r11,
                        checkedRescaleStaticFD!(1, 1)(
                            lhs,
                            rhs)))
                    return false;

                auto r12 =
                    referenceRescale!(1, 2)(
                        lhs,
                        rhs);

                if (!sameResult(
                        r12,
                        checkedRescaleStaticFC!(1, 2)(
                            lhs,
                            rhs)))
                    return false;

                if (!sameResult(
                        r12,
                        checkedRescaleStaticFD!(1, 2)(
                            lhs,
                            rhs)))
                    return false;

                auto r21 =
                    referenceRescale!(2, 1)(
                        lhs,
                        rhs);

                if (!sameResult(
                        r21,
                        checkedRescaleStaticFC!(2, 1)(
                            lhs,
                            rhs)))
                    return false;

                if (!sameResult(
                        r21,
                        checkedRescaleStaticFD!(2, 1)(
                            lhs,
                            rhs)))
                    return false;

                auto r715 =
                    referenceRescale!(7, 15)(
                        lhs,
                        rhs);

                if (!sameResult(
                        r715,
                        checkedRescaleStaticFC!(7, 15)(
                            lhs,
                            rhs)))
                    return false;

                if (!sameResult(
                        r715,
                        checkedRescaleStaticFD!(7, 15)(
                            lhs,
                            rhs)))
                    return false;
            }
        }
    }

    return true;
}

static assert(differentialProbe());


/*
 * Codegen wrappers.
 */

extern(C)
RescaleResult r04_23fc_1_1(long a, long b)
{
    return checkedRescaleStaticFC!(1, 1)(a, b);
}

extern(C)
RescaleResult r04_23fc_1_2(long a, long b)
{
    return checkedRescaleStaticFC!(1, 2)(a, b);
}

extern(C)
RescaleResult r04_23fc_2_1(long a, long b)
{
    return checkedRescaleStaticFC!(2, 1)(a, b);
}

extern(C)
RescaleResult r04_23fc_7_15(long a, long b)
{
    return checkedRescaleStaticFC!(7, 15)(a, b);
}


extern(C)
RescaleResult r04_23fd_1_1(long a, long b)
{
    return checkedRescaleStaticFD!(1, 1)(a, b);
}

extern(C)
RescaleResult r04_23fd_1_2(long a, long b)
{
    return checkedRescaleStaticFD!(1, 2)(a, b);
}

extern(C)
RescaleResult r04_23fd_2_1(long a, long b)
{
    return checkedRescaleStaticFD!(2, 1)(a, b);
}

extern(C)
RescaleResult r04_23fd_7_15(long a, long b)
{
    return checkedRescaleStaticFD!(7, 15)(a, b);
}


void main()
{
    assert(differentialProbe());
}
