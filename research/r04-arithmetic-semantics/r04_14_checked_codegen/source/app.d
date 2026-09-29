module app;

enum CheckedStatus { value, overflow }

struct Checked(T)
{
    CheckedStatus status;
    T payload;
}

private ulong magnitude(long value) @safe pure nothrow @nogc
{
    return value < 0
        ? cast(ulong)(-(value + 1)) + 1
        : cast(ulong)value;
}

/*
 * These five kernels preserve the arithmetic used by the validated
 * R04.14 Probe 3.  The wrappers below provide stable code-generation
 * targets with runtime operands.
 */

pragma(inline, true)
private Checked!long checkedAddLong(long x, long y)
    @safe pure nothrow @nogc
{
    if (y > 0 && x > long.max - y)
        return Checked!long(CheckedStatus.overflow, 0);
    if (y < 0 && x < long.min - y)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, x + y);
}

pragma(inline, true)
private Checked!long checkedSubLong(long x, long y)
    @safe pure nothrow @nogc
{
    if (y > 0 && x < long.min + y)
        return Checked!long(CheckedStatus.overflow, 0);
    if (y < 0 && x > long.max + y)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, x - y);
}

pragma(inline, true)
private Checked!ulong checkedAddUlong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    if (x > ulong.max - y)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, x + y);
}

pragma(inline, true)
private Checked!long checkedMulLong(long x, long y)
    @safe pure nothrow @nogc
{
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

pragma(inline, true)
private Checked!ulong checkedMulUlong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    if (x == 0 || y == 0)
        return Checked!ulong(CheckedStatus.value, 0);

    if (x > ulong.max / y)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, x * y);
}


/*
 * Stable runtime entry points.
 *
 * pragma(inline, false) prevents the experiment from disappearing into
 * the caller.  extern(C) gives the assembly predictable symbol names.
 */

extern(C) pragma(inline, false)
Checked!long probe_checked_add_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedAddLong(x, y);
}

extern(C) pragma(inline, false)
Checked!long probe_checked_sub_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedSubLong(x, y);
}

extern(C) pragma(inline, false)
Checked!ulong probe_checked_add_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedAddUlong(x, y);
}

extern(C) pragma(inline, false)
Checked!long probe_checked_mul_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedMulLong(x, y);
}

extern(C) pragma(inline, false)
Checked!ulong probe_checked_mul_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedMulUlong(x, y);
}

void main(string[] args)
{
    // Runtime-derived operands keep all five externally visible probe
    // entry points reachable without making their values compile-time known.
    const long x = cast(long)args.length;
    const long y = cast(long)(args.length + 1);
    const ulong ux = cast(ulong)args.length;
    const ulong uy = cast(ulong)(args.length + 1);

    auto a = probe_checked_add_long(x, y);
    auto b = probe_checked_sub_long(x, y);
    auto c = probe_checked_add_ulong(ux, uy);
    auto d = probe_checked_mul_long(x, y);
    auto e = probe_checked_mul_ulong(ux, uy);

    // Observable result prevents removal of the calls without introducing
    // I/O into the measured entry points themselves.
    if (a.status == CheckedStatus.overflow ||
        b.status == CheckedStatus.overflow ||
        c.status == CheckedStatus.overflow ||
        d.status == CheckedStatus.overflow ||
        e.status == CheckedStatus.overflow)
        assert(0);
}
