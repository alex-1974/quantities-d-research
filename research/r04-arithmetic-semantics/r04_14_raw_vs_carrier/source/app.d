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
 * Raw core.checkedint path.
 *
 * bool* deliberately makes the overflow result externally observable
 * without introducing our Checked!ulong return carrier.
 */
extern(C)
pragma(inline, false)
ulong probe_core_raw(ulong x, ulong y, ref bool overflow)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = mulu(x, y, o);
    overflow = o;
    return r;
}

/*
 * Same core.checkedint mechanism, but translated into our carrier.
 */
extern(C)
pragma(inline, false)
Checked!ulong probe_core_carrier(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = mulu(x, y, o);

    if (o)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, r);
}

/*
 * Division-free split32 primitive.
 *
 * Returns the low 64 bits. Overflow is true iff the mathematical
 * product has non-zero bits above bit 63.
 */
extern(C)
pragma(inline, false)
ulong probe_split_raw(ulong x, ulong y, ref bool overflow)
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

    const ulong middle =
        (p00 >> 32) +
        (p01 & mask32) +
        (p10 & mask32);

    const ulong high =
        p11 +
        (p01 >> 32) +
        (p10 >> 32) +
        (middle >> 32);

    const ulong low =
        (p00 & mask32) |
        ((middle & mask32) << 32);

    overflow = high != 0;
    return low;
}

/*
 * Exactly the same split32 arithmetic translated into Checked!ulong.
 */
extern(C)
pragma(inline, false)
Checked!ulong probe_split_carrier(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const ulong r = probe_split_raw(x, y, overflow);

    if (overflow)
        return Checked!ulong(CheckedStatus.overflow, 0);

    return Checked!ulong(CheckedStatus.value, r);
}


@safe pure nothrow @nogc
private void verify(ulong x, ulong y)
{
    bool coreOverflow = false;
    bool splitOverflow = false;

    const ulong coreValue =
        probe_core_raw(x, y, coreOverflow);

    const ulong splitValue =
        probe_split_raw(x, y, splitOverflow);

    assert(coreOverflow == splitOverflow);

    /*
     * core.checkedint returns the truncated low 64 bits on overflow,
     * so the raw values should agree in both success and overflow cases.
     */
    assert(coreValue == splitValue);

    const coreCarrier = probe_core_carrier(x, y);
    const splitCarrier = probe_split_carrier(x, y);

    assert(coreCarrier.status == splitCarrier.status);

    if (coreCarrier.status == CheckedStatus.value)
        assert(coreCarrier.payload == splitCarrier.payload);
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

    verify(x, y);
}
