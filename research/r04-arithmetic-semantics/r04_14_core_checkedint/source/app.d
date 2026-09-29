module app;

import core.checkedint : adds, addu, subs, subu, muls, mulu;

enum CheckedStatus
{
    value,
    overflow
}

struct Checked(T)
{
    CheckedStatus status;
    T payload;
}

pragma(inline, true)
private Checked!long checkedAddLong(long x, long y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = adds(x, y, overflow);

    if (overflow)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, value);
}

pragma(inline, true)
private Checked!long checkedSubLong(long x, long y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = subs(x, y, overflow);

    if (overflow)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, value);
}

pragma(inline, true)
private Checked!ulong checkedAddUlong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = addu(x, y, overflow);

    if (overflow)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, value);
}

pragma(inline, true)
private Checked!ulong checkedSubUlong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = subu(x, y, overflow);

    if (overflow)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, value);
}

pragma(inline, true)
private Checked!long checkedMulLong(long x, long y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = muls(x, y, overflow);

    if (overflow)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(CheckedStatus.value, value);
}

pragma(inline, true)
private Checked!ulong checkedMulUlong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const value = mulu(x, y, overflow);

    if (overflow)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, value);
}

extern(C):

pragma(inline, false)
Checked!long probe_checked_add_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedAddLong(x, y);
}

pragma(inline, false)
Checked!long probe_checked_sub_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedSubLong(x, y);
}

pragma(inline, false)
Checked!ulong probe_checked_add_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedAddUlong(x, y);
}

pragma(inline, false)
Checked!ulong probe_checked_sub_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedSubUlong(x, y);
}

pragma(inline, false)
Checked!long probe_checked_mul_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedMulLong(x, y);
}

pragma(inline, false)
Checked!ulong probe_checked_mul_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedMulUlong(x, y);
}

extern(D):

void main(string[] args)
{
    const long x = cast(long)args.length;
    const long y = cast(long)(args.length + 1);
    const ulong ux = cast(ulong)args.length;
    const ulong uy = cast(ulong)(args.length + 1);

    auto a = probe_checked_add_long(x, y);
    auto b = probe_checked_sub_long(x, y);
    auto c = probe_checked_add_ulong(ux, uy);
    auto d = probe_checked_sub_ulong(ux, uy);
    auto e = probe_checked_mul_long(x, y);
    auto f = probe_checked_mul_ulong(ux, uy);

    if (a.status == CheckedStatus.overflow ||
        b.status == CheckedStatus.overflow ||
        c.status == CheckedStatus.overflow ||
        d.status == CheckedStatus.overflow ||
        e.status == CheckedStatus.overflow ||
        f.status == CheckedStatus.overflow)
        assert(0);
}
