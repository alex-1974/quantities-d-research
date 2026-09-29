module app;

import core.checkedint : mulu;
import core.time : MonoTime;

enum dataSize = 1024;
enum iterations = 20_000_000;

enum Workload
{
    small,
    fullWidthExact,
    overflow
}

struct Pair
{
    ulong x;
    ulong y;
}

@safe pure nothrow @nogc
private ulong mix(ulong x)
{
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    return x * 0x2545F4914F6CDD1DUL;
}

@safe pure nothrow @nogc
private void fill(ref Pair[dataSize] data, Workload workload)
{
    ulong state = 0x9E3779B97F4A7C15UL;

    foreach (ref pair; data)
    {
        state = mix(state);
        const ulong a = state;

        state = mix(state);
        const ulong b = state;

        final switch (workload)
        {
            case Workload.small:
                pair.x = (a & 0xFFFFUL) + 1;
                pair.y = (b & 0xFFFFUL) + 1;
                break;

            case Workload.fullWidthExact:
                /*
                 * x genuinely occupies the upper 32 bits, while y is chosen
                 * so the mathematical product still fits in ulong.
                 */
                pair.x = (a | (1UL << 63));
                pair.y = 1;
                break;

            case Workload.overflow:
                /*
                 * Both operands occupy the upper half and therefore their
                 * product cannot fit in ulong.
                 */
                pair.x = a | (1UL << 63);
                pair.y = b | (1UL << 63);
                break;
        }
    }
}

pragma(inline, false)
@safe nothrow @nogc
private ulong run(ref Pair[dataSize] data, out ulong overflowCount)
{
    ulong checksum = 0;
    ulong overflows = 0;

    foreach (i; 0 .. iterations)
    {
        const ref pair = data[i & (dataSize - 1)];

        bool overflow = false;
        const ulong value = mulu(pair.x, pair.y, overflow);

        checksum += value;
        overflows += cast(ulong)overflow;
    }

    overflowCount = overflows;
    return checksum;
}

private void benchmark(Workload workload)
{
    Pair[dataSize] data;
    fill(data, workload);

    // Untimed warm-up.
    ulong warmOverflow;
    const ulong warmChecksum = run(data, warmOverflow);

    const start = MonoTime.currTime;

    ulong overflowCount;
    const ulong checksum = run(data, overflowCount);

    const elapsed = MonoTime.currTime - start;

    const double nsPerOp =
        cast(double)elapsed.total!"nsecs" / cast(double)iterations;

    import std.stdio : writefln;

    writefln(
        "%-16s  %8.3f ns/op  overflow=%d  checksum=%016x  warm=%016x",
        workload,
        nsPerOp,
        overflowCount,
        checksum,
        warmChecksum);
}

void main()
{
    benchmark(Workload.small);
    benchmark(Workload.fullWidthExact);
    benchmark(Workload.overflow);
}
