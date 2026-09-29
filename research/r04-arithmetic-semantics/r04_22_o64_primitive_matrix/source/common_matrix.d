module app;

import core.checkedint;
import core.time : MonoTime;
import std.algorithm : sort;
import std.array : staticArray;
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

enum Workload
{
    small,
    boundaryExact,
    overflow
}

@trusted nothrow @nogc
void prepare(Workload workload)
{
    foreach (i; 0 .. dataSize)
    {
        final switch (workload)
        {
            case Workload.small:
                signedA[i] = (i & 1) ? -cast(long)(i % 97 + 1)
                                     :  cast(long)(i % 97 + 1);
                signedB[i] = (i & 2) ? -cast(long)(i % 31 + 1)
                                     :  cast(long)(i % 31 + 1);

                unsignedA[i] = cast(ulong)(i % 97 + 1);
                unsignedB[i] = cast(ulong)(i % 31 + 1);
                break;

            case Workload.boundaryExact:
                signedA[i] = (i & 1)
                    ? long.max - cast(long)(i % 1024)
                    : long.min + cast(long)(i % 1024);
                signedB[i] = (i & 1) ? 0 : 0;

                unsignedA[i] = ulong.max - cast(ulong)(i % 1024);
                unsignedB[i] = 0;
                break;

            case Workload.overflow:
                signedA[i] = (i & 1) ? long.max : long.min;
                signedB[i] = (i & 1) ? 2 : -2;

                unsignedA[i] = ulong.max - cast(ulong)(i % 1024);
                unsignedB[i] = 2;
                break;
        }
    }
}

struct BenchResult
{
    ulong checksum;
    ulong overflowCount;
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

alias Runner = BenchResult function() nothrow @nogc;

void benchmark(string operation, Workload workload, Runner runner)
{
    prepare(workload);

    // Warm-up.
    auto warm = runner();

    double[runs] samples;

    foreach (run; 0 .. runs)
    {
        const start = MonoTime.currTime;
        const result = runner();
        const stop = MonoTime.currTime;

        const elapsedNs =
            cast(double)((stop - start).total!"nsecs");
        samples[run] = elapsedNs / cast(double)iterations;

        writefln(
            "%-5s %-13s run %s: %8.3f ns/op  ov=%s checksum=%s",
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
        "%-5s %-13s MEDIAN: %8.3f ns/op",
        operation,
        workload,
        median);

    // Keep warm-up observable too.
    if (warm.checksum == ulong.max && warm.overflowCount == ulong.max)
        writeln("unreachable");
}

void runMatrix()
{
    foreach (workload;
        [
            Workload.small,
            Workload.boundaryExact,
            Workload.overflow
        ])
    {
        benchmark("adds", workload, &runAdds);
        benchmark("addu", workload, &runAddu);
        benchmark("subs", workload, &runSubs);
        benchmark("muls", workload, &runMuls);
        benchmark("mulu", workload, &runMulu);
        writeln();
    }
}

void main()
{
    assert(semanticProbe());

    writeln("R04.22 semantic smoke PASS");
    writeln("dataSize=", dataSize,
            " iterations=", iterations,
            " runs=", runs);
    writeln("boundscheck=off");
    writeln();

    runMatrix();
}
