module app;

import core.checkedint : mulu;

enum Status : ubyte
{
    value,
    overflow
}

/*
 * A: current research shape.
 * status first, payload second.
 */
struct CarrierA
{
    Status status;
    ulong payload;
}

/*
 * B: payload first, bool second.
 */
struct CarrierB
{
    ulong payload;
    bool overflow;
}

/*
 * C: payload first, explicit status second.
 */
struct CarrierC
{
    ulong payload;
    Status status;
}

static assert(CarrierA.sizeof == 16);
static assert(CarrierB.sizeof == 16);
static assert(CarrierC.sizeof == 16);

extern(C):

pragma(inline, false)
ulong probe_raw(ulong x, ulong y, ref bool overflow)
    @safe pure nothrow @nogc
{
    bool o = false;
    const ulong r = mulu(x, y, o);
    overflow = o;
    return r;
}

pragma(inline, false)
CarrierA probe_carrier_a(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const ulong r = mulu(x, y, overflow);

    if (overflow)
        return CarrierA(Status.overflow, 0);

    return CarrierA(Status.value, r);
}

pragma(inline, false)
CarrierB probe_carrier_b(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const ulong r = mulu(x, y, overflow);

    if (overflow)
        return CarrierB(0, true);

    return CarrierB(r, false);
}

pragma(inline, false)
CarrierC probe_carrier_c(ulong x, ulong y)
    @safe pure nothrow @nogc
{
    bool overflow = false;
    const ulong r = mulu(x, y, overflow);

    if (overflow)
        return CarrierC(0, Status.overflow);

    return CarrierC(r, Status.value);
}

extern(D):

@safe pure nothrow @nogc
private void verify(ulong x, ulong y)
{
    bool rawOverflow = false;
    const ulong raw = probe_raw(x, y, rawOverflow);

    const a = probe_carrier_a(x, y);
    const b = probe_carrier_b(x, y);
    const c = probe_carrier_c(x, y);

    assert((a.status == Status.overflow) == rawOverflow);
    assert(b.overflow == rawOverflow);
    assert((c.status == Status.overflow) == rawOverflow);

    if (!rawOverflow)
    {
        assert(a.payload == raw);
        assert(b.payload == raw);
        assert(c.payload == raw);
    }
}

@safe pure nothrow @nogc
ulong ctfeProbe()
{
    verify(0, 0);
    verify(1, ulong.max);
    verify(2, ulong.max);

    verify(uint.max, uint.max);
    verify(1UL << 32, 1);
    verify(1UL << 32, 1UL << 32);

    verify(ulong.max, 1);
    verify(ulong.max, 2);
    verify(ulong.max, ulong.max);

    return 1;
}

enum ctfe = ctfeProbe();
static assert(ctfe == 1);

void main(string[] args)
{
    const ulong x =
        cast(ulong)args.length;

    const ulong y =
        (cast(ulong)args.length << 32) |
        cast(ulong)(args.length + 1);

    verify(x, y);
}
