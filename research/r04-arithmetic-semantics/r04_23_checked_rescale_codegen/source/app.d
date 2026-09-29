module app;

import core.checkedint;
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
 * Computes exactly:
 *
 *     (lhs * rhs * numerator) / denominator
 *
 * without allowing intermediate overflow to change the mathematical
 * result.
 *
 * Probe 23 deliberately uses a signed long result carrier. It tests the
 * O64 signed checked-rescale mechanism, not the final public API.
 */
@safe pure nothrow @nogc
RescaleResult checkedRescale(
    long lhs,
    long rhs,
    ulong numerator,
    ulong denominator)
{
    if (denominator == 0)
        return RescaleResult(0, RescaleStatus.inexact);

    const negative = (lhs < 0) != (rhs < 0);

    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);
    ulong n = numerator;
    ulong d = denominator;

    /*
     * Cancel denominator against every multiplicative factor before
     * multiplication.
     */
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
    const limit = negative ? signMagnitude
                           : cast(ulong)long.max;

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

        return RescaleResult(
            -cast(long)product,
            RescaleStatus.exact);
    }

    return RescaleResult(
        cast(long)product,
        RescaleStatus.exact);
}

@safe pure nothrow @nogc
bool semanticProbe()
{
    RescaleResult r;

    // Exact, no cancellation required.
    r = checkedRescale(6, 7, 1, 1);
    if (r.status != RescaleStatus.exact || r.value != 42)
        return false;

    // Exact only because cancellation happens before multiplication.
    r = checkedRescale(long.max, 2, 1, 2);
    if (r.status != RescaleStatus.exact || r.value != long.max)
        return false;

    // Cancellation distributed across factors.
    r = checkedRescale(6, 10, 7, 15);
    if (r.status != RescaleStatus.exact || r.value != 28)
        return false;

    // Mathematically non-integral.
    r = checkedRescale(5, 7, 1, 2);
    if (r.status != RescaleStatus.inexact)
        return false;

    // Exact mathematical integer, but outside signed long result range.
    r = checkedRescale(long.max, 2, 1, 1);
    if (r.status != RescaleStatus.overflow)
        return false;

    // Negative exact result.
    r = checkedRescale(-6, 7, 1, 1);
    if (r.status != RescaleStatus.exact || r.value != -42)
        return false;

    // long.min must remain representable.
    r = checkedRescale(long.min, 1, 1, 1);
    if (r.status != RescaleStatus.exact || r.value != long.min)
        return false;

    // long.min * -1 is mathematically +2^63 -> overflow.
    r = checkedRescale(long.min, -1, 1, 1);
    if (r.status != RescaleStatus.overflow)
        return false;

    // Zero remains exact.
    r = checkedRescale(0, long.max, ulong.max, 1);
    if (r.status != RescaleStatus.exact || r.value != 0)
        return false;

    return true;
}

static assert(semanticProbe());

extern(C)
RescaleResult r04_23_checked_rescale(
    long lhs,
    long rhs,
    ulong numerator,
    ulong denominator)
{
    return checkedRescale(lhs, rhs, numerator, denominator);
}

void main()
{
    assert(semanticProbe());
    writeln("R04.23 semantic + CTFE smoke PASS");
}
