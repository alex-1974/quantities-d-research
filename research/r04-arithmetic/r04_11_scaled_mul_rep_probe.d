module r04_11_scaled_mul_rep_probe;

import std.traits : isIntegral, isSigned;

// Research-only exact signed-magnitude oracle for values arising from
// (<=64-bit integral operand) * (<=64-bit integral operand) * signed 64-bit K.
//
// We only need ordering and multiplication by endpoint values. Magnitude is
// represented as two 64-bit limbs; multiplication is implemented from 32-bit
// limbs so no intermediate exceeds ulong.

private struct U128
{
    ulong hi;
    ulong lo;
}

private struct S128
{
    bool negative;
    U128 magnitude;
}

private int cmpU128(U128 a, U128 b)
{
    if (a.hi < b.hi) return -1;
    if (a.hi > b.hi) return 1;
    if (a.lo < b.lo) return -1;
    if (a.lo > b.lo) return 1;
    return 0;
}

private int cmpS128(S128 a, S128 b)
{
    if (a.negative != b.negative)
        return a.negative ? -1 : 1;

    auto c = cmpU128(a.magnitude, b.magnitude);
    return a.negative ? -c : c;
}

private U128 mul64(ulong a, ulong b)
{
    enum ulong mask = 0xffff_ffffUL;
    ulong a0 = a & mask;
    ulong a1 = a >> 32;
    ulong b0 = b & mask;
    ulong b1 = b >> 32;

    ulong p00 = a0 * b0;
    ulong p01 = a0 * b1;
    ulong p10 = a1 * b0;
    ulong p11 = a1 * b1;

    ulong middle = (p00 >> 32) + (p01 & mask) + (p10 & mask);
    ulong lo = (p00 & mask) | (middle << 32);
    ulong hi = p11 + (p01 >> 32) + (p10 >> 32) + (middle >> 32);
    return U128(hi, lo);
}

private ulong absMagnitude(long value)
{
    // Avoid -long.min overflow.
    return value < 0
        ? cast(ulong)(-(value + 1)) + 1
        : cast(ulong)value;
}

private S128 mulSigned64(long a, long b)
{
    bool neg = (a < 0) != (b < 0);
    auto mag = mul64(absMagnitude(a), absMagnitude(b));
    if (mag.hi == 0 && mag.lo == 0)
        neg = false;
    return S128(neg, mag);
}

private S128 fromSigned64(long value)
{
    return S128(value < 0, U128(0, absMagnitude(value)));
}

private S128 fromUnsigned64(ulong value)
{
    return S128(false, U128(0, value));
}

private struct Endpoint
{
    bool negative;
    ulong magnitude;
}

private Endpoint minEndpoint(T)()
    if (isIntegral!T)
{
    static if (isSigned!T)
        return Endpoint(true, absMagnitude(cast(long) T.min));
    else
        return Endpoint(false, 0);
}

private Endpoint maxEndpoint(T)()
    if (isIntegral!T)
{
    static if (isSigned!T)
        return Endpoint(false, cast(ulong) T.max);
    else
        return Endpoint(false, cast(ulong) T.max);
}

private S128 multiplyEndpoints(Endpoint a, Endpoint b)
{
    auto mag = mul64(a.magnitude, b.magnitude);
    bool neg = a.negative != b.negative;
    if (mag.hi == 0 && mag.lo == 0)
        neg = false;
    return S128(neg, mag);
}

private S128 min4(S128 a, S128 b, S128 c, S128 d)
{
    auto r = cmpS128(a, b) <= 0 ? a : b;
    r = cmpS128(r, c) <= 0 ? r : c;
    return cmpS128(r, d) <= 0 ? r : d;
}

private S128 max4(S128 a, S128 b, S128 c, S128 d)
{
    auto r = cmpS128(a, b) >= 0 ? a : b;
    r = cmpS128(r, c) >= 0 ? r : c;
    return cmpS128(r, d) >= 0 ? r : d;
}

private struct Range
{
    S128 min;
    S128 max;
}

private Range productRange(A, B)()
    if (isIntegral!A && isIntegral!B)
{
    enum amin = minEndpoint!A;
    enum amax = maxEndpoint!A;
    enum bmin = minEndpoint!B;
    enum bmax = maxEndpoint!B;

    enum p1 = multiplyEndpoints(amin, bmin);
    enum p2 = multiplyEndpoints(amin, bmax);
    enum p3 = multiplyEndpoints(amax, bmin);
    enum p4 = multiplyEndpoints(amax, bmax);

    return Range(min4(p1,p2,p3,p4), max4(p1,p2,p3,p4));
}

// For the first Gate-6 probe we deliberately restrict K to positive values.
// That is enough to prove widening caused by canonical integer rescaling.
// General 128x64 scaling is a separate follow-up if needed.
private Range scaledProductRange(A, B, ulong K)()
    if (isIntegral!A && isIntegral!B)
{
    enum r = productRange!(A,B);
    static if (K == 0)
        return Range(fromSigned64(0), fromSigned64(0));
    else
    {
        // The focused examples below are chosen so each endpoint magnitude
        // still fits ulong before scaling. This keeps this probe small and
        // avoids pretending to be a general BigInt implementation.
        assert(r.min.magnitude.hi == 0);
        assert(r.max.magnitude.hi == 0);

        auto loMag = mul64(r.min.magnitude.lo, K);
        auto hiMag = mul64(r.max.magnitude.lo, K);
        return Range(
            S128(r.min.negative, loMag),
            S128(r.max.negative, hiMag));
    }
}

private bool contains(T)(Range r)
    if (isIntegral!T)
{
    static if (isSigned!T)
    {
        enum lo = fromSigned64(cast(long) T.min);
        enum hi = fromSigned64(cast(long) T.max);
        return cmpS128(r.min, lo) >= 0 && cmpS128(r.max, hi) <= 0;
    }
    else
    {
        enum lo = fromUnsigned64(0);
        enum hi = fromUnsigned64(cast(ulong) T.max);
        return cmpS128(r.min, lo) >= 0 && cmpS128(r.max, hi) <= 0;
    }
}

template ScaledMulRep(A, B, ulong K)
    if (isIntegral!A && isIntegral!B)
{
    enum r = scaledProductRange!(A,B,K);

    static if (!r.min.negative)
    {
        static if (contains!ubyte(r)) alias ScaledMulRep = ubyte;
        else static if (contains!ushort(r)) alias ScaledMulRep = ushort;
        else static if (contains!uint(r)) alias ScaledMulRep = uint;
        else static if (contains!ulong(r)) alias ScaledMulRep = ulong;
        else alias ScaledMulRep = void;
    }
    else
    {
        static if (contains!byte(r)) alias ScaledMulRep = byte;
        else static if (contains!short(r)) alias ScaledMulRep = short;
        else static if (contains!int(r)) alias ScaledMulRep = int;
        else static if (contains!long(r)) alias ScaledMulRep = long;
        else alias ScaledMulRep = void;
    }
}

// Prove the primitive 64x64 -> 128 oracle first.
enum max64square = mul64(ulong.max, ulong.max);
static assert(max64square.hi == ulong.max - 1);
static assert(max64square.lo == 1);

// Isolate byte*byte range before testing type selection.
enum byteByteRange = scaledProductRange!(byte, byte, 1);
static assert(cmpS128(byteByteRange.min, fromSigned64(-16256)) == 0);
static assert(cmpS128(byteByteRange.max, fromSigned64(16384)) == 0);
static assert(!contains!byte(byteByteRange));
static assert(contains!short(byteByteRange));

// K=1 recovers representative ordinary product behavior.
static assert(is(ScaledMulRep!(byte, byte, 1) == short));
static assert(is(ScaledMulRep!(ubyte, ubyte, 1) == ushort));
static assert(is(ScaledMulRep!(int, int, 1) == long));
static assert(is(ScaledMulRep!(uint, uint, 1) == ulong));

// Integer canonical rescaling can require a wider result.
static assert(is(ScaledMulRep!(byte, byte, 1000) == int));

// Zero scale collapses the range.
static assert(is(ScaledMulRep!(long, long, 0) == ubyte));

enum expected = cast(long) byte.max * cast(long) byte.max * 1000;
static assert(expected == 16_129_000);
static assert(expected <= int.max);
