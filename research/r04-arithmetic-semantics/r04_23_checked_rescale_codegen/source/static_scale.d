module static_scale;

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

@safe pure nothrow @nogc
RescaleResult checkedRescaleStatic(ulong Numerator, ulong Denominator)(
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
    const limit = negative ? signMagnitude : cast(ulong) long.max;

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
            return RescaleResult(long.min, RescaleStatus.exact);

        return RescaleResult(-cast(long) product, RescaleStatus.exact);
    }

    return RescaleResult(cast(long) product, RescaleStatus.exact);
}


/*
 * Representative compile-time scale specializations.
 */

extern(C)
RescaleResult r04_23_static_1_1(long lhs, long rhs)
{
    return checkedRescaleStatic!(1, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23_static_1_2(long lhs, long rhs)
{
    return checkedRescaleStatic!(1, 2)(lhs, rhs);
}

extern(C)
RescaleResult r04_23_static_2_1(long lhs, long rhs)
{
    return checkedRescaleStatic!(2, 1)(lhs, rhs);
}

extern(C)
RescaleResult r04_23_static_7_15(long lhs, long rhs)
{
    return checkedRescaleStatic!(7, 15)(lhs, rhs);
}


@safe pure nothrow @nogc
bool semanticProbe()
{
    auto r = checkedRescaleStatic!(1, 1)(6, 7);
    if (r.status != RescaleStatus.exact || r.value != 42)
        return false;

    r = checkedRescaleStatic!(1, 2)(long.max, 2);
    if (r.status != RescaleStatus.exact || r.value != long.max)
        return false;

    r = checkedRescaleStatic!(7, 15)(6, 10);
    if (r.status != RescaleStatus.exact || r.value != 28)
        return false;

    r = checkedRescaleStatic!(1, 2)(5, 7);
    if (r.status != RescaleStatus.inexact)
        return false;

    r = checkedRescaleStatic!(2, 1)(long.max, 1);
    if (r.status != RescaleStatus.overflow)
        return false;

    r = checkedRescaleStatic!(1, 1)(-6, 7);
    if (r.status != RescaleStatus.exact || r.value != -42)
        return false;

    r = checkedRescaleStatic!(1, 1)(long.min, 1);
    if (r.status != RescaleStatus.exact || r.value != long.min)
        return false;

    r = checkedRescaleStatic!(1, 1)(long.min, -1);
    if (r.status != RescaleStatus.overflow)
        return false;

    r = checkedRescaleStatic!(7, 15)(0, long.max);
    if (r.status != RescaleStatus.exact || r.value != 0)
        return false;

    return true;
}

static assert(semanticProbe());

void main()
{
    assert(semanticProbe());
}
