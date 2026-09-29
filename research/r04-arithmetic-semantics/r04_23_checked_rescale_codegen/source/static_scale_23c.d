module static_scale_23c;

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
 * Probe 23b reference kernel.
 *
 * Numerator and Denominator are compile-time values, but the algorithm
 * deliberately retains the general three-GCD structure so that Probe 23c
 * can be compared against it.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticB(ulong Numerator, ulong Denominator)(
    long lhs,
    long rhs)
{
    static assert(Denominator != 0);

    const negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);
    ulong n = Numerator;
    ulong d = Denominator;

    auto g = gcd(a, d);
    a /= g;
    d /= g;

    g = gcd(b, d);
    b /= g;
    d /= g;

    g = gcd(n, d);
    n /= g;
    d /= g;

    if (d != 1)
        return RescaleResult(0, RescaleStatus.inexact);

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
            return RescaleResult(0, RescaleStatus.overflow);

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
 * Probe 23c candidate.
 *
 * Contract used here:
 *
 * ProductCanonicalRescale is represented by normalized ExactRatio.
 * Therefore:
 *
 *     gcd(Numerator, Denominator) == 1
 *
 * for the positive magnitudes used by this probe.
 *
 * After cancellation of Denominator against a and b, the remaining d
 * is still a divisor of the original Denominator. Therefore Numerator
 * cannot cancel any remaining factor of d.
 *
 * Consequences:
 *
 *   1. Denominator == 1 is a compile-time fast path.
 *   2. Only a and b need denominator cancellation.
 *   3. gcd(Numerator, d) is unnecessary.
 *   4. If d != 1 afterwards, the result is inexact.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescaleStaticC(ulong Numerator, ulong Denominator)(
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
 * Code-generation entry points.
 */

extern(C)
RescaleResult r04_23c_static_1_1(long lhs, long rhs)
{
    return checkedRescaleStaticC!(1, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23c_static_1_2(long lhs, long rhs)
{
    return checkedRescaleStaticC!(1, 2)(lhs, rhs);
}

extern(C)
RescaleResult r04_23c_static_2_1(long lhs, long rhs)
{
    return checkedRescaleStaticC!(2, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23c_static_7_15(long lhs, long rhs)
{
    return checkedRescaleStaticC!(7, 15)(lhs, rhs);
}


/*
 * Direct semantic checks.
 */

@safe pure nothrow @nogc
bool directSemanticProbe()
{
    auto r = checkedRescaleStaticC!(1, 1)(6, 7);

    if (r.status != RescaleStatus.exact ||
        r.value != 42)
        return false;

    /*
     * Critical cancellation case:
     *
     * long.max * 2 would overflow, but
     *
     *     long.max * 2 / 2 == long.max
     *
     * is mathematically exact and representable.
     */
    r = checkedRescaleStaticC!(1, 2)(
        long.max,
        2);

    if (r.status != RescaleStatus.exact ||
        r.value != long.max)
        return false;

    r = checkedRescaleStaticC!(7, 15)(
        6,
        10);

    if (r.status != RescaleStatus.exact ||
        r.value != 28)
        return false;

    r = checkedRescaleStaticC!(1, 2)(
        5,
        7);

    if (r.status != RescaleStatus.inexact)
        return false;

    r = checkedRescaleStaticC!(2, 1)(
        long.max,
        1);

    if (r.status != RescaleStatus.overflow)
        return false;

    r = checkedRescaleStaticC!(1, 1)(
        -6,
        7);

    if (r.status != RescaleStatus.exact ||
        r.value != -42)
        return false;

    r = checkedRescaleStaticC!(1, 1)(
        long.min,
        1);

    if (r.status != RescaleStatus.exact ||
        r.value != long.min)
        return false;

    r = checkedRescaleStaticC!(1, 1)(
        long.min,
        -1);

    if (r.status != RescaleStatus.overflow)
        return false;

    r = checkedRescaleStaticC!(7, 15)(
        0,
        long.max);

    if (r.status != RescaleStatus.exact ||
        r.value != 0)
        return false;

    return true;
}


/*
 * Differential checks against the Probe 23b reference.
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
                    checkedRescaleStaticB!(1, 1)(
                        lhs,
                        rhs),
                    checkedRescaleStaticC!(1, 1)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticB!(1, 2)(
                        lhs,
                        rhs),
                    checkedRescaleStaticC!(1, 2)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticB!(2, 1)(
                        lhs,
                        rhs),
                    checkedRescaleStaticC!(2, 1)(
                        lhs,
                        rhs)))
                return false;

            if (!sameResult(
                    checkedRescaleStaticB!(7, 15)(
                        lhs,
                        rhs),
                    checkedRescaleStaticC!(7, 15)(
                        lhs,
                        rhs)))
                return false;
        }
    }

    return true;
}

static assert(directSemanticProbe());
static assert(differentialProbe());

void main()
{
    assert(directSemanticProbe());
    assert(differentialProbe());
}
