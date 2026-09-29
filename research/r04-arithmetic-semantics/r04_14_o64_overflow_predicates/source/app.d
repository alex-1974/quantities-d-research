module app;

import std.traits : isIntegral, isSigned;

enum CheckedStatus { value, overflow }

struct Checked(T)
{
    CheckedStatus status;
    T payload;

    @property bool hasValue() const @safe pure nothrow @nogc
    {
        return status == CheckedStatus.value;
    }
}

private ulong magnitude(T)(T value) @safe pure nothrow @nogc
    if (isIntegral!T && isSigned!T)
{
    return value < 0
        ? cast(ulong)(-(cast(long)value + 1)) + 1
        : cast(ulong)value;
}

private Checked!long checkedAddLong(A, B)(A a, B b)
    @safe pure nothrow @nogc
    if (isIntegral!A && isIntegral!B &&
        A.max <= long.max && B.max <= long.max)
{
    const long x = cast(long)a;
    const long y = cast(long)b;

    if (y > 0 && x > long.max - y)
        return Checked!long(CheckedStatus.overflow, 0);
    if (y < 0 && x < long.min - y)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, x + y);
}

private Checked!long checkedSubLong(A, B)(A a, B b)
    @safe pure nothrow @nogc
    if (isIntegral!A && isIntegral!B &&
        A.max <= long.max && B.max <= long.max)
{
    const long x = cast(long)a;
    const long y = cast(long)b;

    if (y > 0 && x < long.min + y)
        return Checked!long(CheckedStatus.overflow, 0);
    if (y < 0 && x > long.max + y)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, x - y);
}

private Checked!ulong checkedAddUlong(A, B)(A a, B b)
    @safe pure nothrow @nogc
    if (isIntegral!A && isIntegral!B &&
        !isSigned!A && !isSigned!B)
{
    const ulong x = cast(ulong)a;
    const ulong y = cast(ulong)b;

    if (x > ulong.max - y)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, x + y);
}

private Checked!long checkedMulLong(A, B)(A a, B b)
    @safe pure nothrow @nogc
    if (isIntegral!A && isIntegral!B &&
        A.max <= long.max && B.max <= long.max)
{
    const long x = cast(long)a;
    const long y = cast(long)b;

    if (x == 0 || y == 0)
        return Checked!long(CheckedStatus.value, 0);

    const bool negative = (x < 0) != (y < 0);
    const ulong ax = magnitude(x);
    const ulong ay = magnitude(y);

    const ulong limit = negative
        ? cast(ulong)long.max + 1UL
        : cast(ulong)long.max;

    if (ax > limit / ay)
        return Checked!long(CheckedStatus.overflow, 0);

    const ulong mag = ax * ay;

    if (!negative)
        return Checked!long(CheckedStatus.value, cast(long)mag);

    if (mag == cast(ulong)long.max + 1UL)
        return Checked!long(CheckedStatus.value, long.min);

    return Checked!long(CheckedStatus.value, -cast(long)mag);
}

private Checked!ulong checkedMulUlong(A, B)(A a, B b)
    @safe pure nothrow @nogc
    if (isIntegral!A && isIntegral!B &&
        !isSigned!A && !isSigned!B)
{
    const ulong x = cast(ulong)a;
    const ulong y = cast(ulong)b;

    if (x == 0 || y == 0)
        return Checked!ulong(CheckedStatus.value, 0);

    if (x > ulong.max / y)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, x * y);
}

@safe pure nothrow @nogc
long attributeProbe()
{
    auto a = checkedAddLong(long.max, 0);
    auto b = checkedSubLong(long.min, 0);
    auto c = checkedMulLong(long.min, 1);
    auto d = checkedAddUlong(ulong.max, 0u);
    auto e = checkedMulUlong(ulong.max, 1u);

    assert(a.hasValue && a.payload == long.max);
    assert(b.hasValue && b.payload == long.min);
    assert(c.hasValue && c.payload == long.min);
    assert(d.hasValue && d.payload == ulong.max);
    assert(e.hasValue && e.payload == ulong.max);
    return 1;
}

enum ctfe = attributeProbe();
static assert(ctfe == 1);

// long addition boundaries
static assert(checkedAddLong(long.max, 0).hasValue);
static assert(!checkedAddLong(long.max, 1).hasValue);
static assert(checkedAddLong(long.min, 0).hasValue);
static assert(!checkedAddLong(long.min, -1).hasValue);
static assert(checkedAddLong(long.min, long.max).payload == -1);

// mixed-width signed-domain addition
static assert(checkedAddLong(long.max, uint(0)).hasValue);
static assert(!checkedAddLong(long.max, uint(1)).hasValue);
static assert(checkedAddLong(long.min, uint.max).hasValue);
static assert(checkedAddLong(long(-1), uint.max).payload ==
    cast(long)uint.max - 1);

// ulong addition
static assert(checkedAddUlong(ulong.max, 0UL).hasValue);
static assert(!checkedAddUlong(ulong.max, 1UL).hasValue);
static assert(checkedAddUlong(ulong.max - uint.max, uint.max).payload ==
    ulong.max);

// long subtraction boundaries
static assert(checkedSubLong(long.min, 0).hasValue);
static assert(!checkedSubLong(long.min, 1).hasValue);
static assert(checkedSubLong(long.max, 0).hasValue);
static assert(!checkedSubLong(long.max, -1).hasValue);
static assert(checkedSubLong(long(0), uint.max).payload == -cast(long)uint.max);

// long multiplication boundaries
static assert(checkedMulLong(long.max, 1).payload == long.max);
static assert(!checkedMulLong(long.max, 2).hasValue);
static assert(checkedMulLong(long.min, 1).payload == long.min);
static assert(!checkedMulLong(long.min, -1).hasValue);
static assert(checkedMulLong(long.min, 0).payload == 0);
static assert(checkedMulLong(long(-1), uint.max).payload ==
    -cast(long)uint.max);

// ulong multiplication boundaries
static assert(checkedMulUlong(ulong.max, 1UL).payload == ulong.max);
static assert(!checkedMulUlong(ulong.max, 2UL).hasValue);
static assert(checkedMulUlong(ulong.max, 0UL).payload == 0);
static assert(checkedMulUlong(ulong.max / uint.max, uint.max).hasValue);

void main()
{
    import std.stdio : writeln;
    writeln("R04.14 Probe 3 PASS");
}
