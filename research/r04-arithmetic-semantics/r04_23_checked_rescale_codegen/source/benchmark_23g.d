module benchmark_23g;

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
 * 23f-C candidate:
 * structural specialization + division-based overflow proof.
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
            -cast(long)product,
            RescaleStatus.exact);
    }

    return RescaleResult(
        cast(long)product,
        RescaleStatus.exact);
}


/*
 * 23f-D candidate:
 * same structure + core.checkedint.mulu.
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
            : cast(ulong)long.max;

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
            -cast(long)product,
            RescaleStatus.exact);
    }

    return RescaleResult(
        cast(long)product,
        RescaleStatus.exact);
}


enum size_t dataSize = 1024;
enum size_t mask = dataSize - 1;

__gshared long[dataSize] lhsData;
__gshared long[dataSize] rhsData;

__gshared ulong sinkValue;
__gshared ulong sinkStatus;


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
        lhsData[i] =
            long.max - cast(long)(i * 2);

        rhsData[i] = 1;
    }
}

void prepareCancellation2()
{
    foreach (i; 0 .. dataSize)
    {
        lhsData[i] =
            cast(long)(2 * i + 1);

        rhsData[i] = 2;
    }
}

void prepareScale2Exact()
{
    foreach (i; 0 .. dataSize)
    {
        /*
         * lhs * rhs * 2 remains exactly representable.
         *
         * Non-trivial values ensure the compile-time numerator
         * multiplication remains part of the hot path.
         */
        lhsData[i] =
            cast(long)((i % 1000) + 1);

        rhsData[i] =
            cast(long)(((i * 13) % 1000) + 1);
    }
}

void prepareCancellation15()
{
    foreach (i; 0 .. dataSize)
    {
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
    return checkedRescaleStaticFC!(1, 1)(a, b);
}

RescaleResult d11(long a, long b)
{
    return checkedRescaleStaticFD!(1, 1)(a, b);
}

RescaleResult c12(long a, long b)
{
    return checkedRescaleStaticFC!(1, 2)(a, b);
}

RescaleResult d12(long a, long b)
{
    return checkedRescaleStaticFD!(1, 2)(a, b);
}

RescaleResult c21(long a, long b)
{
    return checkedRescaleStaticFC!(2, 1)(a, b);
}

RescaleResult d21(long a, long b)
{
    return checkedRescaleStaticFD!(2, 1)(a, b);
}

RescaleResult c715(long a, long b)
{
    return checkedRescaleStaticFC!(7, 15)(a, b);
}

RescaleResult d715(long a, long b)
{
    return checkedRescaleStaticFD!(7, 15)(a, b);
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
        const r =
            kernel(
                lhsData[i & mask],
                rhsData[i & mask]);

        valueAccumulator ^=
            cast(ulong)r.value +
            cast(ulong)i;

        localStatusCount +=
            cast(ulong)r.status;
    }

    const elapsed =
        MonoTime.currTime - start;

    sinkValue ^= valueAccumulator;
    sinkStatus ^= localStatusCount;

    statusCount = localStatusCount;

    return
        cast(double)elapsed.total!"nsecs" /
        cast(double)iterations;
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
        "R04.23g iterations=%s runs=%s dataSize=%s",
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

    prepareScale2Exact();

    runCase(
        "2/1 exact",
        &c21,
        &d21,
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
