module app;

import std.bigint : BigInt;
import std.stdio : writeln;

enum Status : ubyte { exact, inexact, overflow }

struct Result
{
    Status status;
    long value;
}

private ulong magnitude(long x) @safe pure nothrow @nogc
{
    return x < 0 ? cast(ulong)(-(x + 1)) + 1UL : cast(ulong)x;
}

private ulong gcd(ulong a, ulong b) @safe pure nothrow @nogc
{
    while (b != 0) { const r = a % b; a = b; b = r; }
    return a;
}

private void cancel(ref ulong factor, ref ulong denominator)
    @safe pure nothrow @nogc
{
    const g = gcd(factor, denominator);
    factor /= g;
    denominator /= g;
}

Result kernel(long lhs, long rhs, ulong numerator, ulong denominator)
    @safe pure nothrow @nogc
{
    assert(denominator != 0);

    if (lhs == 0 || rhs == 0 || numerator == 0)
        return Result(Status.exact, 0);

    const negative = (lhs < 0) != (rhs < 0);
    ulong a = magnitude(lhs);
    ulong b = magnitude(rhs);
    ulong n = numerator;
    ulong d = denominator;

    // Full cancellation against every numerator factor. If anything remains
    // in d, the rational result cannot be integral.
    cancel(a, d);
    cancel(b, d);
    cancel(n, d);

    if (d != 1)
        return Result(Status.inexact, 0);

    const ulong limit = negative
        ? cast(ulong)long.max + 1UL
        : cast(ulong)long.max;

    // Multiply only after cancellation and prove each step fits the final
    // magnitude domain. This prevents false intermediate overflow.
    if (a != 0 && b > limit / a)
        return Result(Status.overflow, 0);
    const ulong ab = a * b;

    if (ab != 0 && n > limit / ab)
        return Result(Status.overflow, 0);
    const ulong mag = ab * n;

    if (!negative)
        return Result(Status.exact, cast(long)mag);
    if (mag == cast(ulong)long.max + 1UL)
        return Result(Status.exact, long.min);
    return Result(Status.exact, -cast(long)mag);
}

struct Oracle
{
    Status status;
    BigInt value;
}

Oracle oracle(long lhs, long rhs, ulong numerator, ulong denominator)
{
    BigInt x = BigInt(lhs) * BigInt(rhs) * BigInt(numerator);
    BigInt d = BigInt(denominator);
    if (x % d != 0) return Oracle(Status.inexact, BigInt(0));
    BigInt q = x / d;
    if (q < BigInt(long.min) || q > BigInt(long.max))
        return Oracle(Status.overflow, BigInt(0));
    return Oracle(Status.exact, q);
}

void main()
{
    immutable long[] vals = [
        long.min, long.min + 1, -4, -3, -2, -1, 0, 1, 2, 3, 4,
        long.max / 2, long.max - 1, long.max
    ];
    immutable ulong[] scales = [
        1UL, 2UL, 3UL, 4UL, 5UL, 6UL, 7UL, 8UL,
        cast(ulong)uint.max, cast(ulong)long.max, ulong.max
    ];

    size_t checks;
    foreach (a; vals)
    foreach (b; vals)
    foreach (n; scales)
    foreach (d; scales)
    {
        auto got = kernel(a, b, n, d);
        auto exact = oracle(a, b, n, d);
        assert(got.status == exact.status);
        if (got.status == Status.exact)
            assert(BigInt(got.value) == exact.value);
        ++checks;
    }

    // Explicit regression for false intermediate overflow.
    auto r = kernel(long.max, 2, 3, 6);
    assert(r.status == Status.exact && r.value == long.max);

    // CTFE + attributes.
    enum ctfe = kernel(long.min, 2, 1, 2);
    static assert(ctfe.status == Status.exact && ctfe.value == long.min);

    writeln("R04.14 Probe 8 PASS: ", checks, " oracle comparisons");
}
