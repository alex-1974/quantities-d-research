module benchmark_23e;

import core.checkedint : mulu;
import core.time : MonoTime;
import std.stdio : writefln;

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
 * Probe 23c candidate:
 * normalized compile-time ratio + explicit D==1 specialization +
 * division-based final overflow check.
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


/*
 * Probe 23d candidate:
 * identical cancellation semantics, but core.checkedint.mulu
 * for final magnitude multiplication.
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
        negative
            ? signMagnitude
            : cast(ulong) long.max;

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
 * Benchmark data.
 *
 * Power-of-two size makes indexing cheap and deterministic.
 */
enum size_t dataSize = 1024;
enum size_t mask = dataSize - 1;

__gshared long[dataSize] lhsData;
__gshared long[dataSize] rhsData;

__gshared ulong sinkValue;
__gshared ulong sinkStatus;


/*
 * Workloads:
 *
 * exactSmall:
 *   ordinary exact values.
 *
 * exactWide:
 *   values exercise broad 64-bit magnitudes without overflow.
 *
 * cancellation:
 *   D > 1 and exactness requires denominator cancellation.
 *
 * overflow:
 *   final mathematical result does not fit long.
 */

void prepareExactSmall()
{
    foreach (i; 0 .. dataSize)
    {
        lhsData[i] =
            cast(long)((i % 1000) + 1);

        rhsData[i] =
            cast(long)(((i * 17) % 1000) + 1);
    }
}

void prepareExactWide()
{
    foreach (i; 0 .. dataSize)
    {
        /*
         * Large lhs, but rhs == 1.
         * This keeps the result exact while exercising full-width
         * magnitude handling.
         */
        lhsData[i] =
            long.max - cast(long)(i * 2);

        rhsData[i] = 1;
    }
}

void prepareCancellation2()
{
    foreach (i; 0 .. dataSize)
    {
        /*
         * (odd * 2) / 2 -> odd
         *
         * Exact only after denominator cancellation.
         */
        lhsData[i] =
            cast(long)(2 * i + 1);

        rhsData[i] = 2;
    }
}

void prepareCancellation15()
{
    foreach (i; 0 .. dataSize)
    {
        /*
         * (15*k * 1 * 7) / 15 -> 7*k
         */
        lhsData[i] =
            cast(long)(15 * ((i % 1000) + 1));

        rhsData[i] = 1;
    }
}

void prepareOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        lhsData[i] =
            long.max - cast(long)(i & 7);

        rhsData[i] = 2;
    }
}


alias Kernel = RescaleResult function(long, long);


RescaleResult c11(long a, long b)
{
    return checkedRescaleStaticC!(1, 1)(a, b);
}

RescaleResult d11(long a, long b)
{
    return checkedRescaleStaticD!(1, 1)(a, b);
}

RescaleResult c12(long a, long b)
{
    return checkedRescaleStaticC!(1, 2)(a, b);
}

RescaleResult d12(long a, long b)
{
    return checkedRescaleStaticD!(1, 2)(a, b);
}

RescaleResult c715(long a, long b)
{
    return checkedRescaleStaticC!(7, 15)(a, b);
}

RescaleResult d715(long a, long b)
{
    return checkedRescaleStaticD!(7, 15)(a, b);
}


double bench(
    Kernel kernel,
    size_t iterations,
    out ulong statusCount)
{
    ulong valueAccumulator = 0;
    ulong localStatusCount = 0;

    const start = MonoTime.currTime;

    foreach (i; 0 .. iterations)
    {
        const r = kernel(
            lhsData[i & mask],
            rhsData[i & mask]);

        valueAccumulator ^=
            cast(ulong) r.value +
            cast(ulong) i;

        localStatusCount +=
            cast(ulong) r.status;
    }

    const elapsed = MonoTime.currTime - start;

    sinkValue ^= valueAccumulator;
    sinkStatus ^= localStatusCount;

    statusCount = localStatusCount;

    return
        cast(double) elapsed.total!"nsecs" /
        cast(double) iterations;
}


void runCase(
    string label,
    Kernel cKernel,
    Kernel dKernel,
    size_t iterations,
    int runs)
{
    writefln("\nCASE %s", label);

    foreach (run; 0 .. runs)
    {
        ulong cStatus;
        ulong dStatus;

        const cNs =
            bench(
                cKernel,
                iterations,
                cStatus);

        const dNs =
            bench(
                dKernel,
                iterations,
                dStatus);

        writefln(
            "run=%d C=%.3f ns D=%.3f ns ratio(D/C)=%.4f Cstatus=%s Dstatus=%s",
            run + 1,
            cNs,
            dNs,
            dNs / cNs,
            cStatus,
            dStatus);
    }
}


void main()
{
    enum size_t iterations = 20_000_000;
    enum int runs = 5;

    writefln(
        "R04.23e iterations=%s runs=%s dataSize=%s",
        iterations,
        runs,
        dataSize);

    prepareExactSmall();

    runCase(
        "1/1 exact-small",
        &c11,
        &d11,
        iterations,
        runs);

    prepareExactWide();

    runCase(
        "1/1 exact-wide",
        &c11,
        &d11,
        iterations,
        runs);

    prepareCancellation2();

    runCase(
        "1/2 cancellation-exact",
        &c12,
        &d12,
        iterations,
        runs);

    prepareCancellation15();

    runCase(
        "7/15 cancellation-exact",
        &c715,
        &d715,
        iterations,
        runs);

    prepareOverflow();

    runCase(
        "1/1 overflow",
        &c11,
        &d11,
        iterations,
        runs);

    writefln(
        "\nsinkValue=%s sinkStatus=%s",
        sinkValue,
        sinkStatus);
}
