module app;

import std.traits : isIntegral, isSigned;

enum CheckedFailure : ubyte { overflow }

struct CheckedResult(T)
{
private:
    T payload_;
    bool hasValue_;

public:
    @property bool hasValue() const @safe pure nothrow @nogc { return hasValue_; }

    static CheckedResult value(T v) @safe pure nothrow @nogc
    {
        CheckedResult r;
        r.payload_ = v;
        r.hasValue_ = true;
        return r;
    }

    static CheckedResult overflow() @safe pure nothrow @nogc
    {
        return CheckedResult.init;
    }

    bool tryValue(out T v) const @safe pure nothrow @nogc
    {
        if (!hasValue_) return false;
        v = payload_;
        return true;
    }

    bool tryFailure(out CheckedFailure f) const @safe pure nothrow @nogc
    {
        if (hasValue_) return false;
        f = CheckedFailure.overflow;
        return true;
    }
}

struct LengthDim {}
struct AreaDim {}
struct Metre { alias Dimension = LengthDim; }
struct SquareMetre { alias Dimension = AreaDim; }

struct Length
{
    alias Dimension = LengthDim;
    alias CanonicalUnit = Metre;
    enum closedAdditiveValue = true;
    enum scalableValue = true;

    template ProductWith(Rhs)
    {
        static if (is(Rhs == Length)) alias ProductWith = Area;
        else alias ProductWith = void;
    }
}

struct Area
{
    alias Dimension = AreaDim;
    alias CanonicalUnit = SquareMetre;
}

struct Radius
{
    alias Dimension = LengthDim;
    alias CanonicalUnit = Metre;
}

struct Quantity(Spec, Rep)
{
private:
    Rep value_;
public:
    static Quantity fromCanonical(Rep v) @safe pure nothrow @nogc
    {
        return Quantity(v);
    }
    @property Rep canonicalValue() const @safe pure nothrow @nogc { return value_; }
}

template AddResult(A, B)
{
    static if (is(A == B) && __traits(hasMember, A, "closedAdditiveValue") &&
               A.closedAdditiveValue)
        alias AddResult = A;
    else alias AddResult = void;
}

alias SubResult(A, B) = AddResult!(A, B);

template ProductResultSpec(A, B)
{
    static if (__traits(hasMember, A, "ProductWith"))
        alias ProductResultSpec = A.ProductWith!B;
    else alias ProductResultSpec = void;
}

enum O64Domain { signed64, unsigned64, mixed, unavailable }

template AddDomain(A, B)
{
    static if (!isIntegral!A || !isIntegral!B)
        enum AddDomain = O64Domain.unavailable;
    else static if (A.sizeof < 8 && B.sizeof < 8)
        enum AddDomain = O64Domain.unavailable; // Class W, not this API.
    else static if (isSigned!A && isSigned!B)
        enum AddDomain = O64Domain.signed64;
    else static if (!isSigned!A && !isSigned!B)
        enum AddDomain = O64Domain.unsigned64;
    else
    {
        alias S = typeof(isSigned!A ? A.init : B.init);
        alias U = typeof(isSigned!A ? B.init : A.init);
        static if (U.max <= long.max)
            enum AddDomain = O64Domain.signed64;
        else
            enum AddDomain = O64Domain.mixed;
    }
}

alias MulDomain(A, B) = AddDomain!(A, B);

template SubDomain(A, B)
{
    static if (!isIntegral!A || !isIntegral!B)
        enum SubDomain = O64Domain.unavailable;
    else static if (A.sizeof < 8 && B.sizeof < 8)
        enum SubDomain = O64Domain.unavailable;
    else static if (A.max <= long.max && B.max <= long.max)
        enum SubDomain = O64Domain.signed64;
    else
        enum SubDomain = O64Domain.mixed;
}

template ResultRep(alias Domain)
{
    static if (Domain == O64Domain.signed64) alias ResultRep = long;
    else static if (Domain == O64Domain.unsigned64) alias ResultRep = ulong;
    else alias ResultRep = void;
}

private ulong mag(long x) @safe pure nothrow @nogc
{
    return x < 0 ? cast(ulong)(-(x + 1)) + 1UL : cast(ulong)x;
}

private CheckedResult!long addL(long x, long y) @safe pure nothrow @nogc
{
    if ((y > 0 && x > long.max - y) || (y < 0 && x < long.min - y))
        return CheckedResult!long.overflow();
    return CheckedResult!long.value(x + y);
}

private CheckedResult!ulong addU(ulong x, ulong y) @safe pure nothrow @nogc
{
    if (x > ulong.max - y) return CheckedResult!ulong.overflow();
    return CheckedResult!ulong.value(x + y);
}

private CheckedResult!long subL(long x, long y) @safe pure nothrow @nogc
{
    if ((y > 0 && x < long.min + y) || (y < 0 && x > long.max + y))
        return CheckedResult!long.overflow();
    return CheckedResult!long.value(x - y);
}

private CheckedResult!long mulL(long x, long y) @safe pure nothrow @nogc
{
    if (x == 0 || y == 0) return CheckedResult!long.value(0);
    const neg = (x < 0) != (y < 0);
    const ax = mag(x), ay = mag(y);
    const limit = neg ? cast(ulong)long.max + 1UL : cast(ulong)long.max;
    if (ax > limit / ay) return CheckedResult!long.overflow();
    const m = ax * ay;
    if (!neg) return CheckedResult!long.value(cast(long)m);
    if (m == cast(ulong)long.max + 1UL)
        return CheckedResult!long.value(long.min);
    return CheckedResult!long.value(-cast(long)m);
}

private CheckedResult!ulong mulU(ulong x, ulong y) @safe pure nothrow @nogc
{
    if (x == 0 || y == 0) return CheckedResult!ulong.value(0);
    if (x > ulong.max / y) return CheckedResult!ulong.overflow();
    return CheckedResult!ulong.value(x * y);
}

auto checkedAdd(LS, LR, RS, RR)(Quantity!(LS, LR) a, Quantity!(RS, RR) b)
    @safe pure nothrow @nogc
    if (!is(AddResult!(LS, RS) == void) &&
        !is(ResultRep!(AddDomain!(LR, RR)) == void))
{
    alias R = ResultRep!(AddDomain!(LR, RR));
    alias Q = Quantity!(AddResult!(LS, RS), R);
    alias Out = CheckedResult!Q;
    static if (is(R == long))
        auto raw = addL(cast(long)a.canonicalValue, cast(long)b.canonicalValue);
    else
        auto raw = addU(cast(ulong)a.canonicalValue, cast(ulong)b.canonicalValue);
    R v;
    if (!raw.tryValue(v)) return Out.overflow();
    return Out.value(Q.fromCanonical(v));
}

auto checkedSub(LS, LR, RS, RR)(Quantity!(LS, LR) a, Quantity!(RS, RR) b)
    @safe pure nothrow @nogc
    if (!is(SubResult!(LS, RS) == void) &&
        !is(ResultRep!(SubDomain!(LR, RR)) == void))
{
    alias R = ResultRep!(SubDomain!(LR, RR));
    alias Q = Quantity!(SubResult!(LS, RS), R);
    alias Out = CheckedResult!Q;
    auto raw = subL(cast(long)a.canonicalValue, cast(long)b.canonicalValue);
    R v;
    if (!raw.tryValue(v)) return Out.overflow();
    return Out.value(Q.fromCanonical(v));
}

auto checkedMul(S, R, X)(Quantity!(S, R) q, X scalar)
    @safe pure nothrow @nogc
    if (isIntegral!X && __traits(hasMember, S, "scalableValue") &&
        S.scalableValue && !is(ResultRep!(MulDomain!(R, X)) == void))
{
    alias RR = ResultRep!(MulDomain!(R, X));
    alias Q = Quantity!(S, RR);
    alias Out = CheckedResult!Q;
    static if (is(RR == long))
        auto raw = mulL(cast(long)q.canonicalValue, cast(long)scalar);
    else
        auto raw = mulU(cast(ulong)q.canonicalValue, cast(ulong)scalar);
    RR v;
    if (!raw.tryValue(v)) return Out.overflow();
    return Out.value(Q.fromCanonical(v));
}

auto checkedMul(LS, LR, RS, RR)(Quantity!(LS, LR) a, Quantity!(RS, RR) b)
    @safe pure nothrow @nogc
    if (!is(ProductResultSpec!(LS, RS) == void) &&
        !is(ResultRep!(MulDomain!(LR, RR)) == void))
{
    // This probe models only the current Length*Length -> Area 1/1 rescale.
    alias R = ResultRep!(MulDomain!(LR, RR));
    alias Q = Quantity!(ProductResultSpec!(LS, RS), R);
    alias Out = CheckedResult!Q;
    static if (is(R == long))
        auto raw = mulL(cast(long)a.canonicalValue, cast(long)b.canonicalValue);
    else
        auto raw = mulU(cast(ulong)a.canonicalValue, cast(ulong)b.canonicalValue);
    R v;
    if (!raw.tryValue(v)) return Out.overflow();
    return Out.value(Q.fromCanonical(v));
}

@safe pure nothrow @nogc
bool ctfeProbe()
{
    auto a = Quantity!(Length, long).fromCanonical(long.max);
    auto z = Quantity!(Length, int).fromCanonical(0);
    auto r = checkedAdd(a, z);
    Quantity!(Length, long) q;
    return r.tryValue(q) && q.canonicalValue == long.max;
}
static assert(ctfeProbe());

static assert(__traits(compiles,
    checkedAdd(Quantity!(Length,long).fromCanonical(1),
               Quantity!(Length,int).fromCanonical(2))));
static assert(!__traits(compiles,
    checkedAdd(Quantity!(Length,long).fromCanonical(1),
               Quantity!(Radius,int).fromCanonical(2))));
static assert(!__traits(compiles,
    checkedAdd(Quantity!(Length,long).fromCanonical(1),
               Quantity!(Length,ulong).fromCanonical(2))));

static assert(__traits(compiles,
    checkedSub(Quantity!(Length,long).fromCanonical(1),
               Quantity!(Length,uint).fromCanonical(2))));
static assert(!__traits(compiles,
    checkedSub(Quantity!(Length,ulong).fromCanonical(1),
               Quantity!(Length,uint).fromCanonical(2))));

static assert(__traits(compiles,
    checkedMul(Quantity!(Length,long).fromCanonical(2), int(3))));
static assert(!__traits(compiles,
    checkedMul(Quantity!(Length,long).fromCanonical(2), ulong(3))));
static assert(!__traits(compiles,
    checkedMul(Quantity!(Radius,long).fromCanonical(2), int(3))));

static assert(__traits(compiles,
    checkedMul(Quantity!(Length,long).fromCanonical(2),
               Quantity!(Length,int).fromCanonical(3))));
static assert(!__traits(compiles,
    checkedMul(Quantity!(Radius,long).fromCanonical(2),
               Quantity!(Radius,int).fromCanonical(3))));

void main()
{
    import std.stdio : writeln;
    auto ov = checkedAdd(
        Quantity!(Length,long).fromCanonical(long.max),
        Quantity!(Length,int).fromCanonical(1));
    assert(!ov.hasValue);

    auto prod = checkedMul(
        Quantity!(Length,long).fromCanonical(3),
        Quantity!(Length,int).fromCanonical(4));
    Quantity!(Area,long) area;
    assert(prod.tryValue(area) && area.canonicalValue == 12);

    writeln("R04.14 Probe 5 PASS");
}
