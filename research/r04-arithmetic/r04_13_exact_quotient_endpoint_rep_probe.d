module r04_13_exact_quotient_endpoint_rep_probe;

import std.traits : isIntegral, isSigned;

// R04.13 probe 8: endpoint-oriented ResultRep selection for exact scaled
// integral Quantity/Quantity quotients.

struct U128
{
    ulong hi;
    ulong lo;
}

private U128 multiply64(ulong a, ulong b) @safe pure nothrow @nogc
{
    enum ulong mask = 0xffff_ffffUL;
    const ulong a0 = a & mask;
    const ulong a1 = a >> 32;
    const ulong b0 = b & mask;
    const ulong b1 = b >> 32;
    const ulong p00 = a0 * b0;
    const ulong p01 = a0 * b1;
    const ulong p10 = a1 * b0;
    const ulong p11 = a1 * b1;
    const ulong middle =
        (p00 >> 32) + (p01 & mask) + (p10 & mask);

    return U128(
        p11 + (p01 >> 32) + (p10 >> 32) + (middle >> 32),
        (p00 & mask) | (middle << 32));
}

private int compare(U128 a, U128 b) @safe pure nothrow @nogc
{
    if (a.hi < b.hi) return -1;
    if (a.hi > b.hi) return 1;
    if (a.lo < b.lo) return -1;
    if (a.lo > b.lo) return 1;
    return 0;
}

private bool scaledFits(
    ulong sourceMagnitude,
    ulong scaleNumerator,
    ulong scaleDenominator,
    ulong resultMagnitudeLimit) @safe pure nothrow @nogc
{
    return compare(
        multiply64(sourceMagnitude, scaleNumerator),
        multiply64(resultMagnitudeLimit, scaleDenominator)) <= 0;
}

private ulong positiveMax(T)() @safe pure nothrow @nogc
    if (isIntegral!T)
{
    return cast(ulong)T.max;
}

private ulong negativeMagnitudeMax(T)() @safe pure nothrow @nogc
    if (isIntegral!T)
{
    static if (isSigned!T)
    {
        static if (T.sizeof == long.sizeof)
            return cast(ulong)long.max + 1UL;
        else
            return cast(ulong)(-(cast(long)T.min));
    }
    else
        return 0;
}

// Exact quotient sign reachability.
//
// lhs >= 0, rhs > 0  -> positive
// lhs >= 0, rhs < 0  -> negative
// lhs < 0,  rhs > 0  -> negative
// lhs < 0,  rhs < 0  -> positive
//
// Every built-in integral RHS contains +1. Signed RHS additionally contains
// -1, so endpoint witnesses do not require assumptions about larger divisors.
template ExactQuotientEnvelope(Lhs, Rhs, ulong N, ulong D)
{
    static assert(isIntegral!Lhs && isIntegral!Rhs);
    static assert(N > 0 && D > 0);

    enum lhsPos = positiveMax!Lhs;
    enum lhsNeg = negativeMagnitudeMax!Lhs;

    // Positive results can always come from positive lhs / +1.
    // If both operands are signed, negative lhs / -1 can expose the larger
    // negative lhs magnitude as a positive result.
    static if (isSigned!Lhs && isSigned!Rhs)
        enum positiveSourceMagnitude =
            lhsNeg > lhsPos ? lhsNeg : lhsPos;
    else
        enum positiveSourceMagnitude = lhsPos;

    // Negative results require exactly one operand sign to be negative.
    static if (isSigned!Lhs)
        enum negativeFromLhs = lhsNeg;
    else
        enum negativeFromLhs = 0UL;

    static if (isSigned!Rhs)
        enum negativeFromRhs = lhsPos;
    else
        enum negativeFromRhs = 0UL;

    enum negativeSourceMagnitude =
        negativeFromLhs > negativeFromRhs
            ? negativeFromLhs
            : negativeFromRhs;

    enum hasNegative = negativeSourceMagnitude != 0;
}

template EnvelopeFits(Env, Candidate)
{
    enum positiveFits = scaledFits(
        Env.positiveSourceMagnitude,
        Env.N,
        Env.D,
        positiveMax!Candidate);

    static if (Env.hasNegative)
    {
        static if (isSigned!Candidate)
            enum negativeFits = scaledFits(
                Env.negativeSourceMagnitude,
                Env.N,
                Env.D,
                negativeMagnitudeMax!Candidate);
        else
            enum negativeFits = false;
    }
    else
        enum negativeFits = true;

    enum EnvelopeFits = positiveFits && negativeFits;
}

template ExactQuotientResultRep(Lhs, Rhs, ulong N, ulong D)
{
    alias Env = ExactQuotientEnvelope!(Lhs, Rhs, N, D);

    // Choose by value-domain capacity, not by signed-first declaration order.
    // For equal storage width, an unsigned type contains every nonnegative
    // value of the signed type and is therefore the smaller sufficient domain
    // when negative results are impossible. If negatives are reachable,
    // unsigned candidates fail EnvelopeFits automatically.
    static if (EnvelopeFits!(Env, ubyte))
        alias ExactQuotientResultRep = ubyte;
    else static if (EnvelopeFits!(Env, byte))
        alias ExactQuotientResultRep = byte;
    else static if (EnvelopeFits!(Env, ushort))
        alias ExactQuotientResultRep = ushort;
    else static if (EnvelopeFits!(Env, short))
        alias ExactQuotientResultRep = short;
    else static if (EnvelopeFits!(Env, uint))
        alias ExactQuotientResultRep = uint;
    else static if (EnvelopeFits!(Env, int))
        alias ExactQuotientResultRep = int;
    else static if (EnvelopeFits!(Env, ulong))
        alias ExactQuotientResultRep = ulong;
    else static if (EnvelopeFits!(Env, long))
        alias ExactQuotientResultRep = long;
    else
        alias ExactQuotientResultRep = void;
}

alias ByteByteEnvelope = ExactQuotientEnvelope!(byte, byte, 1, 1);
static assert(ByteByteEnvelope.positiveSourceMagnitude == 128);
static assert(ByteByteEnvelope.negativeSourceMagnitude == 128);
static assert(ByteByteEnvelope.hasNegative);
static assert(!EnvelopeFits!(ByteByteEnvelope, byte));
static assert(!EnvelopeFits!(ByteByteEnvelope, ubyte));
static assert(EnvelopeFits!(ByteByteEnvelope, short));

// Signed/signed unit-scale division: the positive min/-1 witness forces one
// wider signed representation.
static assert(is(ExactQuotientResultRep!(byte, byte, 1, 1) == short));
static assert(is(ExactQuotientResultRep!(short, short, 1, 1) == int));
static assert(is(ExactQuotientResultRep!(int, int, 1, 1) == long));
static assert(is(ExactQuotientResultRep!(long, long, 1, 1) == void));

// Unsigned/unsigned division cannot produce negative results and needs no
// wider range at unit scale.
static assert(is(ExactQuotientResultRep!(ubyte, ubyte, 1, 1) == ubyte));
static assert(is(ExactQuotientResultRep!(ushort, ushort, 1, 1) == ushort));
static assert(is(ExactQuotientResultRep!(uint, uint, 1, 1) == uint));
static assert(is(ExactQuotientResultRep!(ulong, ulong, 1, 1) == ulong));

// Unsigned lhs / signed rhs can become negative via rhs=-1. A signed result
// must contain both +Lhs.max and -Lhs.max.
static assert(is(ExactQuotientResultRep!(ubyte, byte, 1, 1) == short));
static assert(is(ExactQuotientResultRep!(ushort, short, 1, 1) == int));
static assert(is(ExactQuotientResultRep!(uint, int, 1, 1) == long));
static assert(is(ExactQuotientResultRep!(ulong, long, 1, 1) == void));

// Signed lhs / unsigned rhs retains the lhs sign envelope. At unit scale the
// same signed type is sufficient because rhs=+1 is the worst magnitude case.
static assert(is(ExactQuotientResultRep!(byte, ubyte, 1, 1) == byte));
static assert(is(ExactQuotientResultRep!(short, ushort, 1, 1) == short));
static assert(is(ExactQuotientResultRep!(int, uint, 1, 1) == int));
static assert(is(ExactQuotientResultRep!(long, ulong, 1, 1) == long));

// Rational rescale can shrink the endpoint envelope enough to retain/narrow
// the representation.
static assert(is(ExactQuotientResultRep!(int, int, 1, 1000) == int));
static assert(is(ExactQuotientResultRep!(int, int, 5, 18) == int));

// Enlarging rescale requires a wider representation and may eventually make
// the operation unavailable with built-in integer Reps.
static assert(is(ExactQuotientResultRep!(byte, byte, 1000, 1) == int));
static assert(is(ExactQuotientResultRep!(long, ulong, 2, 1) == void));

// The selected Rep proof is about all exact results over the complete operand
// domains. divisionByZero and inexact remain runtime outcomes; result range
// failure does not need to be one when ResultRep != void.

void main() {}
