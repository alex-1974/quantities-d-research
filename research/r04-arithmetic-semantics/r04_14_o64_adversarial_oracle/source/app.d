module app;

import std.bigint : BigInt;

enum Status { value, overflow }

struct Checked(T)
{
    Status status;
    T value;
    @property bool ok() const @safe pure nothrow @nogc
    {
        return status == Status.value;
    }
}

private ulong magnitude(long value) @safe pure nothrow @nogc
{
    return value < 0
        ? cast(ulong)(-(value + 1)) + 1
        : cast(ulong)value;
}

private Checked!long addL(long x, long y) @safe pure nothrow @nogc
{
    if (y > 0 && x > long.max - y) return Checked!long(Status.overflow, 0);
    if (y < 0 && x < long.min - y) return Checked!long(Status.overflow, 0);
    return Checked!long(Status.value, x + y);
}

private Checked!long subL(long x, long y) @safe pure nothrow @nogc
{
    if (y > 0 && x < long.min + y) return Checked!long(Status.overflow, 0);
    if (y < 0 && x > long.max + y) return Checked!long(Status.overflow, 0);
    return Checked!long(Status.value, x - y);
}

private Checked!long mulL(long x, long y) @safe pure nothrow @nogc
{
    if (x == 0 || y == 0) return Checked!long(Status.value, 0);
    const bool neg = (x < 0) != (y < 0);
    const ulong ax = magnitude(x);
    const ulong ay = magnitude(y);
    const ulong limit = neg ? cast(ulong)long.max + 1UL : cast(ulong)long.max;
    if (ax > limit / ay) return Checked!long(Status.overflow, 0);
    const ulong mag = ax * ay;
    if (!neg) return Checked!long(Status.value, cast(long)mag);
    if (mag == cast(ulong)long.max + 1UL)
        return Checked!long(Status.value, long.min);
    return Checked!long(Status.value, -cast(long)mag);
}

private Checked!ulong addU(ulong x, ulong y) @safe pure nothrow @nogc
{
    if (x > ulong.max - y) return Checked!ulong(Status.overflow, 0);
    return Checked!ulong(Status.value, x + y);
}

private Checked!ulong mulU(ulong x, ulong y) @safe pure nothrow @nogc
{
    if (x == 0 || y == 0) return Checked!ulong(Status.value, 0);
    if (x > ulong.max / y) return Checked!ulong(Status.overflow, 0);
    return Checked!ulong(Status.value, x * y);
}

private bool fitsLong(ref BigInt x)
{
    return x >= BigInt(long.min) && x <= BigInt(long.max);
}

private bool fitsUlong(ref BigInt x)
{
    return x >= BigInt(0) && x <= BigInt(ulong.max);
}

void main()
{
    import std.stdio : writeln;

    immutable long[] signedCases = [
        long.min, long.min + 1, long.min / 2, -4, -3, -2, -1,
        0, 1, 2, 3, 4, long.max / 2, long.max - 1, long.max
    ];
    immutable ulong[] unsignedCases = [
        0UL, 1UL, 2UL, 3UL, 4UL,
        cast(ulong)long.max - 1UL, cast(ulong)long.max,
        cast(ulong)long.max + 1UL,
        ulong.max / 2UL, ulong.max - 1UL, ulong.max
    ];

    size_t checks;

    foreach (x; signedCases)
    foreach (y; signedCases)
    {
        BigInt bx = x;
        BigInt by = y;

        auto exact = bx + by;
        auto got = addL(x, y);
        assert(got.ok == fitsLong(exact));
        if (got.ok) assert(BigInt(got.value) == exact);
        ++checks;

        exact = bx - by;
        got = subL(x, y);
        assert(got.ok == fitsLong(exact));
        if (got.ok) assert(BigInt(got.value) == exact);
        ++checks;

        exact = bx * by;
        got = mulL(x, y);
        assert(got.ok == fitsLong(exact));
        if (got.ok) assert(BigInt(got.value) == exact);
        ++checks;
    }

    foreach (x; unsignedCases)
    foreach (y; unsignedCases)
    {
        BigInt bx = x;
        BigInt by = y;

        auto exact = bx + by;
        auto gotA = addU(x, y);
        assert(gotA.ok == fitsUlong(exact));
        if (gotA.ok) assert(BigInt(gotA.value) == exact);
        ++checks;

        exact = bx * by;
        auto gotM = mulU(x, y);
        assert(gotM.ok == fitsUlong(exact));
        if (gotM.ok) assert(BigInt(gotM.value) == exact);
        ++checks;
    }

    writeln("R04.14 Probe 4 PASS: ", checks, " oracle comparisons");
}
