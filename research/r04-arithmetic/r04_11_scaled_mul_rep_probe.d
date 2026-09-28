module r04_11_scaled_mul_rep_probe;

import std.traits : isIntegral, isSigned;
import core.int128 : Cent;

private enum long signedMin(T) = cast(long) T.min;
private enum ulong unsignedMax(T) = cast(ulong) T.max;

// Research-only exact range model using signed 128-bit arithmetic. This is an
// oracle for built-in <=64-bit operand Reps, not a proposed production API.
private alias Wide = Cent;

private struct Range
{
    Wide min;
    Wide max;
}

private Range repRange(T)()
    if (isIntegral!T)
{
    static if (isSigned!T)
        return Range(cast(Wide) T.min, cast(Wide) T.max);
    else
        return Range(0, cast(Wide) T.max);
}

private Wide min4(Wide a, Wide b, Wide c, Wide d)
{
    Wide r = a < b ? a : b;
    r = r < c ? r : c;
    return r < d ? r : d;
}

private Wide max4(Wide a, Wide b, Wide c, Wide d)
{
    Wide r = a > b ? a : b;
    r = r > c ? r : c;
    return r > d ? r : d;
}

private Range scaledProductRange(A, B, long K)()
    if (isIntegral!A && isIntegral!B)
{
    enum ar = repRange!A;
    enum br = repRange!B;

    enum p1 = ar.min * br.min;
    enum p2 = ar.min * br.max;
    enum p3 = ar.max * br.min;
    enum p4 = ar.max * br.max;

    enum lo = min4(p1, p2, p3, p4);
    enum hi = max4(p1, p2, p3, p4);

    static if (K >= 0)
        return Range(lo * K, hi * K);
    else
        return Range(hi * K, lo * K);
}

private bool contains(T)(Range r)
    if (isIntegral!T)
{
    static if (isSigned!T)
        return r.min >= cast(Wide) T.min &&
               r.max <= cast(Wide) T.max;
    else
        return r.min >= 0 &&
               r.max <= cast(Wide) T.max;
}

template ScaledMulRep(A, B, long K)
    if (isIntegral!A && isIntegral!B)
{
    enum r = scaledProductRange!(A, B, K);

    // Match the existing arithmetic policy: choose by storage width first,
    // and use unsigned only when the complete mathematical range is nonnegative.
    static if (r.min >= 0)
    {
        static if (contains!ubyte(r))
            alias ScaledMulRep = ubyte;
        else static if (contains!ushort(r))
            alias ScaledMulRep = ushort;
        else static if (contains!uint(r))
            alias ScaledMulRep = uint;
        else static if (contains!ulong(r))
            alias ScaledMulRep = ulong;
        else
            alias ScaledMulRep = void;
    }
    else
    {
        static if (contains!byte(r))
            alias ScaledMulRep = byte;
        else static if (contains!short(r))
            alias ScaledMulRep = short;
        else static if (contains!int(r))
            alias ScaledMulRep = int;
        else static if (contains!long(r))
            alias ScaledMulRep = long;
        else
            alias ScaledMulRep = void;
    }
}

// First prove the range oracle independently of Rep selection.
enum byteByteRange = scaledProductRange!(byte, byte, 1);
static assert(byteByteRange.min == -16256);
static assert(byteByteRange.max == 16384);
static assert(!contains!byte(byteByteRange));
static assert(contains!short(byteByteRange));

// K=1 recovers ordinary complete-product range behavior.
static assert(is(ScaledMulRep!(byte, byte, 1) == short));
static assert(is(ScaledMulRep!(ubyte, ubyte, 1) == ushort));
static assert(is(ScaledMulRep!(int, int, 1) == long));
static assert(is(ScaledMulRep!(uint, uint, 1) == ulong));
static assert(is(ScaledMulRep!(long, long, 1) == void));

// Integer canonical rescaling can require a wider result than multiplication
// alone. byte*byte fits short; multiplying that mathematical range by 1000
// requires int.
static assert(is(ScaledMulRep!(byte, byte, 1000) == int));

// A sufficiently large integer rescale can make a formerly admissible product
// impossible in all built-in integral Reps.
static assert(is(ScaledMulRep!(int, int, 1000) == void));

// Zero scale is mathematically total and collapses the result range.
static assert(is(ScaledMulRep!(long, long, 0) == ubyte));

// Negative integer scale reverses the interval and may change signedness needs.
static assert(is(ScaledMulRep!(ubyte, ubyte, -1) == int));

// The range is derived from the complete mathematical expression. No
// intermediate built-in Rep is required by the proof.
enum byteA = byte.max;
enum byteB = byte.max;
enum expected = cast(long) byteA * cast(long) byteB * 1000;
static assert(expected == 16_129_000);
static assert(expected <= int.max);
