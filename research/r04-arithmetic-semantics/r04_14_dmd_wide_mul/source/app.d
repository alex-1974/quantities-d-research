module app;

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
private Checked!long checkedMulLongWide(long x, long y)
    @safe pure nothrow @nogc
{
    const cent wide = cast(cent)x * cast(cent)y;

    if (wide < cast(cent)long.min ||
        wide > cast(cent)long.max)
        return Checked!long(CheckedStatus.overflow, 0);

    return Checked!long(
        CheckedStatus.value,
        cast(long)wide
    );
}

pragma(inline, true)
private Checked!ulong checkedMulUlongWide(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    const ucent wide = cast(ucent)x * cast(ucent)y;

    if (wide > cast(ucent)ulong.max)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(
        CheckedStatus.value,
        cast(ulong)wide
    );
}

extern(C):

pragma(inline, false)
Checked!long probe_wide_mul_long(long x, long y)
    @safe pure nothrow @nogc
{
    return checkedMulLongWide(x, y);
}

pragma(inline, false)
Checked!ulong probe_wide_mul_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedMulUlongWide(x, y);
}

extern(D):

@safe pure nothrow @nogc
long ctfeProbe()
{
    auto a = checkedMulLongWide(long.max, 1);
    assert(a.status == CheckedStatus.value);
    assert(a.payload == long.max);

    auto b = checkedMulLongWide(long.max, 2);
    assert(b.status == CheckedStatus.overflow);

    auto c = checkedMulLongWide(long.min, 1);
    assert(c.status == CheckedStatus.value);
    assert(c.payload == long.min);

    auto d = checkedMulLongWide(long.min, -1);
    assert(d.status == CheckedStatus.overflow);

    auto e = checkedMulUlongWide(ulong.max, 1);
    assert(e.status == CheckedStatus.value);
    assert(e.payload == ulong.max);

    auto f = checkedMulUlongWide(ulong.max, 2);
    assert(f.status == CheckedStatus.overflow);

    return 1;
}

enum ctfe = ctfeProbe();
static assert(ctfe == 1);

void main(string[] args)
{
    const long x = cast(long)args.length;
    const long y = cast(long)(args.length + 1);
    const ulong ux = cast(ulong)args.length;
    const ulong uy = cast(ulong)(args.length + 1);

    auto a = probe_wide_mul_long(x, y);
    auto b = probe_wide_mul_ulong(ux, uy);

    if (a.status == CheckedStatus.overflow ||
        b.status == CheckedStatus.overflow)
        assert(0);
}
