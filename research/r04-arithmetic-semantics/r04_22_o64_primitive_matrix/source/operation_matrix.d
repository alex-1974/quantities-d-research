module operation_matrix;

import core.checkedint;
import core.time : MonoTime;
import std.algorithm : sort;
import std.stdio : writefln, writeln;

enum size_t dataSize = 1024;
enum ulong iterations = 20_000_000;
enum size_t runs = 5;

__gshared long[dataSize] signedA;
__gshared long[dataSize] signedB;
__gshared ulong[dataSize] unsignedA;
__gshared ulong[dataSize] unsignedB;

@safe pure nothrow @nogc
long checkedAdds(long a, long b, ref bool overflow)
{
    return adds(a, b, overflow);
}

@safe pure nothrow @nogc
ulong checkedAddu(ulong a, ulong b, ref bool overflow)
{
    return addu(a, b, overflow);
}

@safe pure nothrow @nogc
long checkedSubs(long a, long b, ref bool overflow)
{
    return subs(a, b, overflow);
}

@safe pure nothrow @nogc
long checkedMuls(long a, long b, ref bool overflow)
{
    return muls(a, b, overflow);
}

@safe pure nothrow @nogc
ulong checkedMulu(ulong a, ulong b, ref bool overflow)
{
    return mulu(a, b, overflow);
}

@safe pure nothrow @nogc
bool semanticProbe()
{
    bool ov;

    ov = false;
    if (checkedAdds(1, 2, ov) != 3 || ov) return false;
    ov = false;
    checkedAdds(long.max, 1, ov);
    if (!ov) return false;

    ov = false;
    if (checkedAddu(1, 2, ov) != 3 || ov) return false;
    ov = false;
    checkedAddu(ulong.max, 1, ov);
    if (!ov) return false;

    ov = false;
    if (checkedSubs(2, 1, ov) != 1 || ov) return false;
    ov = false;
    checkedSubs(long.min, 1, ov);
    if (!ov) return false;

    ov = false;
    if (checkedMuls(-7, 6, ov) != -42 || ov) return false;
    ov = false;
    checkedMuls(long.max, 2, ov);
    if (!ov) return false;

    ov = false;
    if (checkedMulu(7, 6, ov) != 42 || ov) return false;
    ov = false;
    checkedMulu(ulong.max, 2, ov);
    if (!ov) return false;

    return true;
}

static assert(semanticProbe());

struct BenchResult
{
    ulong checksum;
    ulong overflowCount;
}

/*
 * Each preparation routine belongs to exactly one operation/workload.
 * This avoids interpreting an input distribution designed for one
 * arithmetic operation as evidence for another.
 */

@trusted nothrow @nogc
void prepareAddsExact()
{
    foreach (i; 0 .. dataSize)
    {
        signedA[i] = (i & 1)
            ? long.max - cast(long)(2048 + i)
            : long.min + cast(long)(2048 + i);

        signedB[i] = (i & 1)
            ? cast(long)(i & 1023)
            : -cast(long)(i & 1023);
    }
}

@trusted nothrow @nogc
void prepareAddsOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        if (i & 1)
        {
            signedA[i] = long.max - cast(long)(i & 255);
            signedB[i] = 1024;
        }
        else
        {
            signedA[i] = long.min + cast(long)(i & 255);
            signedB[i] = -1024;
        }
    }
}

@trusted nothrow @nogc
void prepareAdduExact()
{
    foreach (i; 0 .. dataSize)
    {
        unsignedA[i] = ulong.max - 4096UL - cast(ulong)i;
        unsignedB[i] = cast(ulong)(i & 1023);
    }
}

@trusted nothrow @nogc
void prepareAdduOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        unsignedA[i] = ulong.max - cast(ulong)(i & 255);
        unsignedB[i] = 1024;
    }
}

@trusted nothrow @nogc
void prepareSubsExact()
{
    foreach (i; 0 .. dataSize)
    {
        signedA[i] = (i & 1)
            ? long.max - cast(long)(2048 + i)
            : long.min + cast(long)(2048 + i);

        signedB[i] = (i & 1)
            ? -cast(long)(i & 1023)
            : cast(long)(i & 1023);
    }
}

@trusted nothrow @nogc
void prepareSubsOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        if (i & 1)
        {
            signedA[i] = long.max - cast(long)(i & 255);
            signedB[i] = -1024;
        }
        else
        {
            signedA[i] = long.min + cast(long)(i & 255);
            signedB[i] = 1024;
        }
    }
}

@trusted nothrow @nogc
void prepareMulsSmall()
{
    foreach (i; 0 .. dataSize)
    {
        signedA[i] = (i & 1)
            ? -cast(long)(i % 97 + 1)
            : cast(long)(i % 97 + 1);

        signedB[i] = (i & 2)
            ? -cast(long)(i % 31 + 1)
            : cast(long)(i % 31 + 1);
    }
}

@trusted nothrow @nogc
void prepareMulsFullWidthExact()
{
    foreach (i; 0 .. dataSize)
    {
        /*
         * Large-magnitude 64-bit operand, but multiplication remains exact.
         * Multiplication by +/-1 deliberately forces the full-width operand
         * through the checked primitive without mathematical overflow.
         */
        signedA[i] = (i & 1)
            ? long.max - cast(long)i
            : long.min + cast(long)i;

        signedB[i] = (i & 2) ? -1 : 1;

        /*
         * long.min * -1 is the sole problematic endpoint.
         */
        if (signedA[i] == long.min && signedB[i] == -1)
            signedB[i] = 1;
    }
}

@trusted nothrow @nogc
void prepareMulsOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        signedA[i] = (i & 1)
            ? long.max - cast(long)(i & 255)
            : long.min + cast(long)(i & 255);

        signedB[i] = (i & 1) ? 2 : -2;
    }
}

@trusted nothrow @nogc
void prepareMuluSmall()
{
    foreach (i; 0 .. dataSize)
    {
        unsignedA[i] = cast(ulong)(i % 97 + 1);
        unsignedB[i] = cast(ulong)(i % 31 + 1);
    }
}

@trusted nothrow @nogc
void prepareMuluFullWidthExact()
{
    foreach (i; 0 .. dataSize)
    {
        unsignedA[i] = ulong.max - cast(ulong)i;
        unsignedB[i] = 1;
    }
}

@trusted nothrow @nogc
void prepareMuluOverflow()
{
    foreach (i; 0 .. dataSize)
    {
        unsignedA[i] = ulong.max - cast(ulong)(i & 255);
        unsignedB[i] = 2;
    }
}

@trusted nothrow @nogc
BenchResult runAdds()
{
    ulong checksum;
    ulong overflowCount;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));
        bool ov = false;
        const value = checkedAdds(signedA[idx], signedB[idx], ov);
        checksum ^= cast(ulong)value;
        overflowCount += ov;
    }

    return BenchResult(checksum, overflowCount);
}

@trusted nothrow @nogc
BenchResult runAddu()
{
    ulong checksum;
    ulong overflowCount;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));
        bool ov = false;
        const value = checkedAddu(unsignedA[idx], unsignedB[idx], ov);
        checksum ^= value;
        overflowCount += ov;
    }

    return BenchResult(checksum, overflowCount);
}

@trusted nothrow @nogc
BenchResult runSubs()
{
    ulong checksum;
    ulong overflowCount;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));
        bool ov = false;
        const value = checkedSubs(signedA[idx], signedB[idx], ov);
        checksum ^= cast(ulong)value;
        overflowCount += ov;
    }

    return BenchResult(checksum, overflowCount);
}

@trusted nothrow @nogc
BenchResult runMuls()
{
    ulong checksum;
    ulong overflowCount;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));
        bool ov = false;
        const value = checkedMuls(signedA[idx], signedB[idx], ov);
        checksum ^= cast(ulong)value;
        overflowCount += ov;
    }

    return BenchResult(checksum, overflowCount);
}

@trusted nothrow @nogc
BenchResult runMulu()
{
    ulong checksum;
    ulong overflowCount;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));
        bool ov = false;
        const value = checkedMulu(unsignedA[idx], unsignedB[idx], ov);
        checksum ^= value;
        overflowCount += ov;
    }

    return BenchResult(checksum, overflowCount);
}

alias Prepare = void function() nothrow @nogc;
alias Runner = BenchResult function() nothrow @nogc;

void benchmark(
    string operation,
    string workload,
    Prepare prepare,
    Runner runner,
    ulong expectedOverflowCount)
{
    prepare();

    auto warm = runner();

    assert(
        warm.overflowCount == expectedOverflowCount,
        "unexpected overflow count");

    double[runs] samples;

    foreach (run; 0 .. runs)
    {
        const start = MonoTime.currTime;
        const result = runner();
        const stop = MonoTime.currTime;

        assert(
            result.overflowCount == expectedOverflowCount,
            "unexpected overflow count");

        const elapsedNs =
            cast(double)((stop - start).total!"nsecs");

        samples[run] =
            elapsedNs / cast(double)iterations;

        writefln(
            "%-5s %-14s run %s: %8.3f ns/op  ov=%s checksum=%s",
            operation,
            workload,
            run + 1,
            samples[run],
            result.overflowCount,
            result.checksum);
    }

    auto ordered = samples[].sort;
    const median = ordered[runs / 2];

    writefln(
        "%-5s %-14s MEDIAN: %8.3f ns/op",
        operation,
        workload,
        median);

    if (warm.checksum == ulong.max &&
        warm.overflowCount == ulong.max)
        writeln("unreachable");
}

void main()
{
    assert(semanticProbe());

    writeln("R04.22 operation-specific matrix");
    writeln("semantic smoke PASS");
    writeln(
        "dataSize=", dataSize,
        " iterations=", iterations,
        " runs=", runs);
    writeln("boundscheck=off");
    writeln();

    benchmark(
        "adds", "exact",
        &prepareAddsExact, &runAdds, 0);
    benchmark(
        "adds", "overflow",
        &prepareAddsOverflow, &runAdds, iterations);

    benchmark(
        "addu", "exact",
        &prepareAdduExact, &runAddu, 0);
    benchmark(
        "addu", "overflow",
        &prepareAdduOverflow, &runAddu, iterations);

    benchmark(
        "subs", "exact",
        &prepareSubsExact, &runSubs, 0);
    benchmark(
        "subs", "overflow",
        &prepareSubsOverflow, &runSubs, iterations);

    benchmark(
        "muls", "small",
        &prepareMulsSmall, &runMuls, 0);
    benchmark(
        "muls", "fullWidthExact",
        &prepareMulsFullWidthExact, &runMuls, 0);
    benchmark(
        "muls", "overflow",
        &prepareMulsOverflow, &runMuls, iterations);

    benchmark(
        "mulu", "small",
        &prepareMuluSmall, &runMulu, 0);
    benchmark(
        "mulu", "fullWidthExact",
        &prepareMuluFullWidthExact, &runMulu, 0);
    benchmark(
        "mulu", "overflow",
        &prepareMuluOverflow, &runMulu, iterations);
}
