module app;

import core.checkedint :
    adds,
    addu,
    subs,
    subu,
    muls,
    mulu;

/*
 * Probe 19
 *
 * Raw O64 primitive codegen only.
 *
 * Deliberately:
 * - no quantities-d carrier
 * - no Quantity wrapper
 * - no benchmark
 * - no allocation
 *
 * Each function returns the arithmetic result and writes the
 * overflow state through a ref parameter.
 */

extern(C):

pragma(inline, false)
@safe pure nothrow @nogc
long probe_add_long(long x, long y, ref bool overflow)
{
    overflow = false;
    return adds(x, y, overflow);
}

pragma(inline, false)
@safe pure nothrow @nogc
long probe_sub_long(long x, long y, ref bool overflow)
{
    overflow = false;
    return subs(x, y, overflow);
}

pragma(inline, false)
@safe pure nothrow @nogc
long probe_mul_long(long x, long y, ref bool overflow)
{
    overflow = false;
    return muls(x, y, overflow);
}

pragma(inline, false)
@safe pure nothrow @nogc
ulong probe_add_ulong(ulong x, ulong y, ref bool overflow)
{
    overflow = false;
    return addu(x, y, overflow);
}

pragma(inline, false)
@safe pure nothrow @nogc
ulong probe_sub_ulong(ulong x, ulong y, ref bool overflow)
{
    overflow = false;
    return subu(x, y, overflow);
}

pragma(inline, false)
@safe pure nothrow @nogc
ulong probe_mul_ulong(ulong x, ulong y, ref bool overflow)
{
    overflow = false;
    return mulu(x, y, overflow);
}

@safe pure nothrow @nogc
bool semanticProbe()
{
    bool o;

    assert(probe_add_long(long.max, 0, o) == long.max && !o);
    assert(probe_add_long(long.max, 1, o) == long.min && o);

    assert(probe_sub_long(long.min, 0, o) == long.min && !o);
    assert(probe_sub_long(long.min, 1, o) == long.max && o);

    assert(probe_mul_long(long.max, 1, o) == long.max && !o);
    assert(probe_mul_long(long.max, 2, o) == -2 && o);
    assert(probe_mul_long(long.min, -1, o) == long.min && o);

    assert(probe_add_ulong(ulong.max, 0, o) == ulong.max && !o);
    assert(probe_add_ulong(ulong.max, 1, o) == 0 && o);

    assert(probe_sub_ulong(0, 0, o) == 0 && !o);
    assert(probe_sub_ulong(0, 1, o) == ulong.max && o);

    assert(probe_mul_ulong(ulong.max, 1, o) == ulong.max && !o);
    assert(probe_mul_ulong(ulong.max, 2, o) == ulong.max - 1 && o);

    return true;
}

enum ctfePass = semanticProbe();
static assert(ctfePass);

void main()
{
    /*
     * Runtime-dependent values keep all wrappers reachable.
     */
    import core.runtime : Runtime;

    auto args = Runtime.args;

    long x = cast(long) args.length;
    long y = x + 1;

    ulong ux = cast(ulong) x;
    ulong uy = cast(ulong) y;

    bool o;

    auto a = probe_add_long(x, y, o);
    auto b = probe_sub_long(x, y, o);
    auto c = probe_mul_long(x, y, o);

    auto d = probe_add_ulong(ux, uy, o);
    auto e = probe_sub_ulong(ux, uy, o);
    auto f = probe_mul_ulong(ux, uy, o);

    /*
     * Prevent whole-program elimination without adding anything
     * to the six functions under inspection.
     */
    if ((cast(ulong)a ^
         cast(ulong)b ^
         cast(ulong)c ^
         d ^ e ^ f) == ulong.max)
    {
        assert(0);
    }
}
