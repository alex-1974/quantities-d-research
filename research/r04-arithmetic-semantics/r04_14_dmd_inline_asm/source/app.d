module app;

import core.checkedint : mulu;

/*
 * A: druntime reference.
 */
extern(C)
pragma(inline, false)
ulong probe_core(ulong x, ulong y, ref bool overflow)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = mulu(x, y, o);
    overflow = o;
    return r;
}

/*
 * B: local copy of the DMD x86-64 mechanism,
 * deliberately not inline.
 *
 * Research only. Not a proposed quantities-d implementation.
 */
pragma(inline, false)
private ulong localMulNoInline(
    ulong x,
    ulong y,
    ref bool overflow)
    @trusted pure nothrow @nogc
{
    ulong r;
    bool o;

    asm pure nothrow @nogc @trusted
    {
        mov RAX, x;
        mul y;
        mov r, RAX;
        setc o;
    }

    overflow |= o;
    return r;
}

extern(C)
pragma(inline, false)
ulong probe_local_noinline(
    ulong x,
    ulong y,
    ref bool overflow)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = localMulNoInline(x, y, o);
    overflow = o;
    return r;
}

/*
 * C: identical mechanism, but explicitly requested inline.
 */
pragma(inline, true)
private ulong localMulInline(
    ulong x,
    ulong y,
    ref bool overflow)
    @trusted pure nothrow @nogc
{
    ulong r;
    bool o;

    asm pure nothrow @nogc @trusted
    {
        mov RAX, x;
        mul y;
        mov r, RAX;
        setc o;
    }

    overflow |= o;
    return r;
}

extern(C)
pragma(inline, false)
ulong probe_local_inline(
    ulong x,
    ulong y,
    ref bool overflow)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = localMulInline(x, y, o);
    overflow = o;
    return r;
}

private void verify(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool aOverflow;
    bool bOverflow;
    bool cOverflow;

    const ulong a = probe_core(x, y, aOverflow);
    const ulong b = probe_local_noinline(x, y, bOverflow);
    const ulong c = probe_local_inline(x, y, cOverflow);

    assert(a == b);
    assert(a == c);
    assert(aOverflow == bOverflow);
    assert(aOverflow == cOverflow);
}

void main(string[] args)
{
    const ulong seed = cast(ulong)args.length;

    verify(seed, seed + 1);
    verify(ulong.max, 1);
    verify(ulong.max, 2);
    verify(1UL << 63, 1);
    verify(1UL << 63, 2);
}
