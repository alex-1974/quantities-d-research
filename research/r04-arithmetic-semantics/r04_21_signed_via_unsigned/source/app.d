module app;

import core.checkedint : muls, mulu;
import core.time : MonoTime;
import std.stdio : writefln;

enum size_t dataSize = 1024;
enum ulong iterations = 20_000_000;

/*
 * Convert a signed long to its unsigned magnitude without
 * overflowing for long.min.
 *
 * For negative x:
 *
 *     magnitude = 0 - cast(ulong)x
 *
 * unsigned arithmetic gives:
 *
 *     abs(long.min) == 2^63
 */
@safe pure nothrow @nogc
ulong magnitude(long x)
{
    const ux = cast(ulong)x;
    return x < 0 ? 0UL - ux : ux;
}

/*
 * Experimental signed checked multiplication.
 *
 * This is deliberately NOT production code.
 *
 * It delegates magnitude multiplication to core.checkedint.mulu,
 * then checks whether the unsigned magnitude is representable in
 * the required signed half-range.
 */
@safe pure nothrow @nogc
long mulsViaUnsigned(long x, long y, ref bool overflow)
{
    overflow = false;

    const negative = (x < 0) != (y < 0);

    const ax = magnitude(x);
    const ay = magnitude(y);

    bool unsignedOverflow = false;
    const product = mulu(ax, ay, unsignedOverflow);

    if (unsignedOverflow)
    {
        overflow = true;
        return cast(long)product;
    }

    enum ulong signMagnitude = 1UL << 63;

    if (negative)
    {
        if (product > signMagnitude)
        {
            overflow = true;
            return cast(long)product;
        }

        /*
         * unsigned subtraction deliberately handles 2^63:
         *
         * product == 2^63 -> long.min
         */
        return cast(long)(0UL - product);
    }

    if (product >= signMagnitude)
    {
        overflow = true;
        return cast(long)product;
    }

    return cast(long)product;
}


/*
 * ------------------------------------------------------------
 * Semantic verification
 * ------------------------------------------------------------
 */

@safe pure nothrow @nogc
void compareOne(long x, long y)
{
    bool referenceOverflow = false;
    bool candidateOverflow = false;

    const reference =
        muls(x, y, referenceOverflow);

    const candidate =
        mulsViaUnsigned(x, y, candidateOverflow);

    assert(referenceOverflow == candidateOverflow);

    /*
     * On success the numerical result must be identical.
     *
     * On overflow core.checkedint returns a truncated low-word
     * result. That representation is not part of quantities-d's
     * public semantics, so only the failure state matters there.
     */
    if (!referenceOverflow)
        assert(reference == candidate);
}

@safe pure nothrow @nogc
bool semanticProbe()
{
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

    foreach (x; values)
        foreach (y; values)
            compareOne(x, y);

    // Explicit important boundaries.
    compareOne(long.min, 1);
    compareOne(long.min, -1);
    compareOne(long.max, 1);
    compareOne(long.max, 2);
    compareOne(-(1L << 32), 1L << 31);
    compareOne(-(1L << 32), -(1L << 31));

    return true;
}

enum ctfePass = semanticProbe();
static assert(ctfePass);


/*
 * ------------------------------------------------------------
 * Benchmark
 * ------------------------------------------------------------
 */

enum Workload : ubyte
{
    small,
    fullWidthExact,
    overflow
}

long[dataSize] lhsData;
long[dataSize] rhsData;

@safe nothrow @nogc
void prepare(Workload workload)
{
    foreach (i; 0 .. dataSize)
    {
        final switch (workload)
        {
            case Workload.small:
                /*
                 * Include both signs instead of benchmarking
                 * positive-only signed arithmetic.
                 */
                long x = cast(long)((i * 37 + 3) & 0xFFFF);
                long y = cast(long)((i * 53 + 5) & 0xFFFF);

                if (i & 1)
                    x = -x;

                if (i & 2)
                    y = -y;

                lhsData[i] = x;
                rhsData[i] = y;
                break;

            case Workload.fullWidthExact:
                /*
                 * Large magnitudes and mixed signs, but exact.
                 */
                long x =
                    long.max -
                    cast(long)(i * 104729);

                if (i & 1)
                    x = -x;

                lhsData[i] = x;
                rhsData[i] = 1;
                break;

            case Workload.overflow:
                /*
                 * Guaranteed signed overflow with both positive
                 * and negative lhs values.
                 */
                long x =
                    long.max -
                    cast(long)(i & 0x3FF);

                if (i & 1)
                    x = -x;

                lhsData[i] = x;
                rhsData[i] = 2;
                break;
        }
    }
}

struct BenchResult
{
    long checksum;
    ulong overflowCount;
}

alias CheckedMul =
    long function(long, long, ref bool)
        @safe pure nothrow @nogc;

/*
 * Typed wrapper around core.checkedint.muls.
 *
 * core.checkedint.muls is overload/template based, so taking
 * &muls directly does not select the long overload.
 */
@safe pure nothrow @nogc
long referenceMuls(long x, long y, ref bool overflow)
{
    return muls(x, y, overflow);
}

@safe nothrow @nogc
BenchResult runKernel(CheckedMul op)
{
    long checksum = 0;
    ulong overflowCount = 0;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));

        bool overflow = false;

        const value =
            op(lhsData[idx], rhsData[idx], overflow);

        checksum ^= value;

        if (overflow)
            ++overflowCount;
    }

    return BenchResult(checksum, overflowCount);
}

@safe
void benchmark(
    string workloadName,
    Workload workload,
    string implementationName,
    CheckedMul op)
{
    prepare(workload);

    auto warmup = runKernel(op);

    auto start = MonoTime.currTime;
    auto result = runKernel(op);
    auto elapsed = MonoTime.currTime - start;

    const ns =
        cast(double)elapsed.total!"nsecs" /
        cast(double)iterations;

    writefln(
        "%-16s %-12s %8.3f ns/op checksum=%s overflow=%s warm=%s/%s",
        workloadName,
        implementationName,
        ns,
        result.checksum,
        result.overflowCount,
        warmup.checksum,
        warmup.overflowCount);
}

void main()
{
    // Runtime verification too.
    assert(semanticProbe());

    foreach (workload; [
        Workload.small,
        Workload.fullWidthExact,
        Workload.overflow
    ])
    {
        string name;

        final switch (workload)
        {
            case Workload.small:
                name = "small";
                break;

            case Workload.fullWidthExact:
                name = "fullWidthExact";
                break;

            case Workload.overflow:
                name = "overflow";
                break;
        }

        benchmark(name, workload, "muls", &referenceMuls);
        benchmark(name, workload, "viaUnsigned", &mulsViaUnsigned);
    }
}
