module app;

import core.checkedint : muls;
import core.time : MonoTime;
import std.stdio : writefln;

enum size_t dataSize = 1024;
enum ulong iterations = 20_000_000;

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
                // Small exact products; exercises cheap/special cases.
                lhsData[i] = cast(long)((i * 37 + 3) & 0xFFFF);
                rhsData[i] = cast(long)((i * 53 + 5) & 0xFFFF);
                break;

            case Workload.fullWidthExact:
                // Large signed values but guaranteed exact:
                // x * 1 == x.
                //
                // Avoid long.min here so this workload remains
                // a straightforward full-width exact case.
                lhsData[i] =
                    long.max -
                    cast(long)(i * 104729);
                rhsData[i] = 1;
                break;

            case Workload.overflow:
                // Guaranteed positive signed overflow.
                lhsData[i] =
                    long.max -
                    cast(long)(i & 0x3FF);
                rhsData[i] = 2;
                break;
        }
    }
}

struct Result
{
    long checksum;
    ulong overflowCount;
}

@safe nothrow @nogc
Result runKernel()
{
    long checksum = 0;
    ulong overflowCount = 0;

    foreach (i; 0 .. iterations)
    {
        const idx = cast(size_t)(i & (dataSize - 1));

        bool overflow = false;
        const value = muls(lhsData[idx], rhsData[idx], overflow);

        // Intentional wrapping checksum; benchmark sink only.
        checksum ^= value;

        if (overflow)
            ++overflowCount;
    }

    return Result(checksum, overflowCount);
}

@safe
void runOne(string name, Workload workload)
{
    prepare(workload);

    // Warmup outside measured interval.
    auto warmup = runKernel();

    auto start = MonoTime.currTime;
    auto result = runKernel();
    auto elapsed = MonoTime.currTime - start;

    const ns =
        cast(double) elapsed.total!"nsecs" /
        cast(double) iterations;

    writefln(
        "%-16s %8.3f ns/op  checksum=%s overflow=%s warm=%s/%s",
        name,
        ns,
        result.checksum,
        result.overflowCount,
        warmup.checksum,
        warmup.overflowCount
    );
}

void main()
{
    runOne("small", Workload.small);
    runOne("fullWidthExact", Workload.fullWidthExact);
    runOne("overflow", Workload.overflow);
}
