module app;

import core.checkedint : mulu;

enum CheckedStatus : ubyte
{
    value,
    overflow
}

struct Checked(T)
{
    CheckedStatus status;
    T payload;
}

/*
 * Semantic reference: druntime core.checkedint.
 */
pragma(inline, true)
private Checked!ulong checkedMulCore(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const ulong r = mulu(x, y, overflow);

    return overflow
        ? Checked!ulong(CheckedStatus.overflow, 0)
        : Checked!ulong(CheckedStatus.value, r);
}

/*
 * Candidate:
 *
 * x = x1 * 2^32 + x0
 * y = y1 * 2^32 + y0
 *
 * Product:
 *   x0*y0
 * + (x0*y1 + x1*y0) * 2^32
 * + x1*y1 * 2^64
 *
 * We need only determine whether bits >= 64 are non-zero.
 */
pragma(inline, true)
private Checked!ulong checkedMulSplit32(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    enum ulong mask32 = 0xffff_ffffUL;

    const ulong x0 = x & mask32;
    const ulong x1 = x >> 32;
    const ulong y0 = y & mask32;
    const ulong y1 = y >> 32;

    const ulong p00 = x0 * y0;
    const ulong p01 = x0 * y1;
    const ulong p10 = x1 * y0;
    const ulong p11 = x1 * y1;

    /*
     * p00 contributes its upper 32 bits to the middle limb.
     *
     * Each term below is at most 2^32-1 squared, so we accumulate
     * the middle column without overflowing ulong:
     *
     *   (p00 >> 32) + low32(p01) + low32(p10)
     *
     * Its bits above bit 31 become part of the high 64 bits.
     */
    const ulong middle =
        (p00 >> 32) +
        (p01 & mask32) +
        (p10 & mask32);

    const ulong high =
        p11 +
        (p01 >> 32) +
        (p10 >> 32) +
        (middle >> 32);

    if (high != 0)
        return Checked!ulong(CheckedStatus.overflow, 0);

    const ulong low =
        (p00 & mask32) |
        ((middle & mask32) << 32);

    return Checked!ulong(CheckedStatus.value, low);
}

extern(C):

pragma(inline, false)
Checked!ulong probe_core_mul_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedMulCore(x, y);
}

pragma(inline, false)
Checked!ulong probe_split_mul_ulong(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    return checkedMulSplit32(x, y);
}

extern(D):

private void verify(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    const a = checkedMulCore(x, y);
    const b = checkedMulSplit32(x, y);

    assert(a.status == b.status);

    if (a.status == CheckedStatus.value)
        assert(a.payload == b.payload);
}

@safe pure nothrow @nogc
ulong ctfeProbe()
{
    verify(0, 0);
    verify(0, ulong.max);
    verify(1, ulong.max);
    verify(2, ulong.max);

    verify(uint.max, uint.max);
    verify(1UL << 32, 1);
    verify(1UL << 32, 1UL << 31);
    verify(1UL << 32, 1UL << 32);

    verify(ulong.max, 1);
    verify(ulong.max, 2);
    verify(ulong.max, ulong.max);

    verify(0xffff_ffff_ffff_ffffUL,
           0x0000_0000_0000_0001UL);

    verify(0x0000_0001_0000_0001UL,
           0x0000_0000_ffff_ffffUL);

    return 1;
}

enum ctfe = ctfeProbe();
static assert(ctfe == 1);

void main(string[] args)
{
    const ulong x = cast(ulong)args.length;
    const ulong y =
        (cast(ulong)args.length << 32) |
        cast(ulong)(args.length + 1);

    const a = probe_core_mul_ulong(x, y);
    const b = probe_split_mul_ulong(x, y);

    if (a.status != b.status)
        assert(0);

    if (a.status == CheckedStatus.value &&
        a.payload != b.payload)
        assert(0);
}
