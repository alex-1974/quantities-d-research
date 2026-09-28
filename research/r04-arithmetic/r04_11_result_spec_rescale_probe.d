module r04_11_result_spec_rescale_probe;

// R04.11 integration probe:
// semantic ResultSpec + mathematical result unit + canonical storage unit + Rep gate.

import std.meta : AliasSeq;
import std.traits : fullyQualifiedName;
import std.traits : isIntegral;

// ----- exact ratio -----

struct ExactRatio(long N, long D)
{
    static assert(D != 0);
    enum numerator = D < 0 ? -N : N;
    enum denominator = D < 0 ? -D : D;
}

private long absLong(long x)
{
    return x < 0 ? -x : x;
}

private long gcd(long a, long b)
{
    a = absLong(a);
    b = absLong(b);
    while (b != 0)
    {
        auto r = a % b;
        a = b;
        b = r;
    }
    return a == 0 ? 1 : a;
}

template ReducedRatio(long N, long D)
{
    static assert(D != 0);
    enum g = gcd(N, D);
    alias ReducedRatio = ExactRatio!(N / g, D / g);
}

template MulRatio(A, B)
{
    alias MulRatio = ReducedRatio!(
        A.numerator * B.numerator,
        A.denominator * B.denominator);
}

template DivRatio(A, B)
{
    static assert(B.numerator != 0);
    alias DivRatio = ReducedRatio!(
        A.numerator * B.denominator,
        A.denominator * B.numerator);
}

// ----- canonical dimensions -----

struct LengthTag {}

struct DimTerm(Tag, int E)
{
    alias DimensionTag = Tag;
    enum exponent = E;
}

struct TermList(Terms...)
{
    alias Items = AliasSeq!Terms;
    enum length = Terms.length;
}

template tagKey(Tag)
{
    enum tagKey = fullyQualifiedName!Tag;
}

template termLess(A, B)
{
    static if (is(A.DimensionTag == B.DimensionTag))
        enum termLess = false;
    else
        enum termLess = tagKey!(A.DimensionTag) < tagKey!(B.DimensionTag);
}

template InsertCanonical(List, Term)
{
    static if (Term.exponent == 0)
        alias InsertCanonical = List;
    else static if (List.length == 0)
        alias InsertCanonical = TermList!Term;
    else static if (is(List.Items[0].DimensionTag == Term.DimensionTag))
    {
        enum exponent = List.Items[0].exponent + Term.exponent;
        static if (exponent == 0)
            alias InsertCanonical = TermList!(List.Items[1 .. $]);
        else
            alias InsertCanonical = TermList!(
                DimTerm!(Term.DimensionTag, exponent),
                List.Items[1 .. $]);
    }
    else static if (termLess!(Term, List.Items[0]))
        alias InsertCanonical = TermList!(Term, List.Items);
    else
    {
        alias Tail = InsertCanonical!(
            TermList!(List.Items[1 .. $]), Term);
        alias InsertCanonical = TermList!(List.Items[0], Tail.Items);
    }
}

template Normalize(Terms...)
{
    static if (Terms.length == 0)
        alias Normalize = TermList!();
    else
    {
        alias Tail = Normalize!(Terms[1 .. $]);
        alias Normalize = InsertCanonical!(Tail, Terms[0]);
    }
}

struct CanonicalDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

template Dimension(Terms...)
{
    alias N = Normalize!Terms;
    alias Dimension = CanonicalDimension!(N.Items);
}

template MulDimension(A, B)
{
    alias MulDimension = Dimension!(
        A.TermsList.Items,
        B.TermsList.Items);
}

alias LengthDimension = Dimension!(DimTerm!(LengthTag, 1));
alias AreaDimension = MulDimension!(LengthDimension, LengthDimension);

// ----- units/specs -----

struct Unit(DimensionT, RatioT)
{
    alias Dimension = DimensionT;
    alias Scale = RatioT;
}

alias Metre = Unit!(LengthDimension, ExactRatio!(1, 1));
alias SquareMetre = Unit!(AreaDimension, ExactRatio!(1, 1));
alias SquareKilometre = Unit!(AreaDimension, ExactRatio!(1_000_000, 1));

struct Length
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductWith(Rhs)
    {
        static if (is(Rhs == Length))
            alias ProductWith = Area;
        else
            alias ProductWith = void;
    }
}

struct Area
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

struct AreaKm2
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareKilometre;
}

template ResultUnit(LhsSpec, RhsSpec)
{
    alias ResultUnit = Unit!(
        MulDimension!(
            LhsSpec.CanonicalUnit.Dimension,
            RhsSpec.CanonicalUnit.Dimension),
        MulRatio!(
            LhsSpec.CanonicalUnit.Scale,
            RhsSpec.CanonicalUnit.Scale));
}

template CanonicalRescale(MathUnit, ResultSpec)
{
    static assert(is(
        MathUnit.Dimension ==
        ResultSpec.CanonicalUnit.Dimension));

    // canonical value = mathematical value * (mathScale / canonicalScale)
    alias CanonicalRescale = DivRatio!(
        MathUnit.Scale,
        ResultSpec.CanonicalUnit.Scale);
}

alias MathLengthProductUnit = ResultUnit!(Length, Length);
static assert(is(MathLengthProductUnit.Dimension == AreaDimension));
static assert(MathLengthProductUnit.Scale.numerator == 1);
static assert(MathLengthProductUnit.Scale.denominator == 1);

alias AreaScale = CanonicalRescale!(MathLengthProductUnit, Area);
static assert(AreaScale.numerator == 1);
static assert(AreaScale.denominator == 1);

alias AreaKm2Scale = CanonicalRescale!(MathLengthProductUnit, AreaKm2);
static assert(AreaKm2Scale.numerator == 1);
static assert(AreaKm2Scale.denominator == 1_000_000);

// Integral direct operators may only use a rescale that is exact for every
// representable integer value. A reduced denominator other than 1 fails that
// value-independent totality requirement.
template integralRescaleIsTotal(Ratio)
{
    enum integralRescaleIsTotal = Ratio.denominator == 1;
}

static assert(integralRescaleIsTotal!AreaScale);
static assert(!integralRescaleIsTotal!AreaKm2Scale);

// Demonstrate why the second case cannot be a silent direct integral operator:
// 3 m * 4 m = 12 m² = 0.000012 km².
enum rawProduct = 3L * 4L;
static assert(rawProduct == 12);
static assert(
    rawProduct * AreaKm2Scale.numerator %
        AreaKm2Scale.denominator != 0);

// Selected values can still be exactly representable under a fractional
// canonical rescale, so a named exact/checked path remains meaningful.
enum exactRawProduct = 1000L * 1000L;
static assert(exactRawProduct == 1_000_000);
static assert(
    exactRawProduct * AreaKm2Scale.numerator %
        AreaKm2Scale.denominator == 0);
static assert(
    exactRawProduct *
        AreaKm2Scale.numerator /
        AreaKm2Scale.denominator == 1);

// Integration invariant: dimension compatibility and canonical storage scale
// are independent checks.
template productDimensionMatches(LhsSpec, RhsSpec, ResultSpec)
{
    enum productDimensionMatches = is(
        MulDimension!(
            LhsSpec.Dimension,
            RhsSpec.Dimension) ==
        ResultSpec.Dimension);
}

static assert(productDimensionMatches!(Length, Length, Area));
static assert(productDimensionMatches!(Length, Length, AreaKm2));

void main()
{
    import std.stdio : writeln;
    writeln("PASS: result-spec canonical rescale probe");
}
