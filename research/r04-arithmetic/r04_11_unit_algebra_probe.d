module r04_11_unit_algebra_probe;

// R04.11: production-shaped unit algebra probe.
// Focus: derived dimensions + exact rational scale propagation.

import std.meta : AliasSeq;
import std.traits : fullyQualifiedName;

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

template PowRatioPositive(A, int P)
{
    static assert(P >= 0);
    static if (P == 0)
        alias PowRatioPositive = ExactRatio!(1, 1);
    else static if (P == 1)
        alias PowRatioPositive = A;
    else
        alias PowRatioPositive =
            MulRatio!(A, PowRatioPositive!(A, P - 1));
}

template PowRatio(A, int P)
{
    static if (P >= 0)
        alias PowRatio = PowRatioPositive!(A, P);
    else
    {
        alias Positive = PowRatioPositive!(A, -P);
        alias PowRatio = ReducedRatio!(
            Positive.denominator,
            Positive.numerator);
    }
}

// ----- Canonical open dimension algebra -----

struct LengthTag {}
struct TimeTag {}

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
        alias InsertCanonical =
            TermList!(List.Items[0], Tail.Items);
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

template NegateTerms(List)
{
    static if (List.length == 0)
        alias NegateTerms = TermList!();
    else
    {
        alias Tail = NegateTerms!(TermList!(List.Items[1 .. $]));
        alias NegateTerms = TermList!(
            DimTerm!(List.Items[0].DimensionTag, -List.Items[0].exponent),
            Tail.Items);
    }
}

template ScaleTerms(List, int P)
{
    static if (List.length == 0)
        alias ScaleTerms = TermList!();
    else
    {
        alias Tail = ScaleTerms!(TermList!(List.Items[1 .. $]), P);
        alias ScaleTerms = TermList!(
            DimTerm!(List.Items[0].DimensionTag,
                     List.Items[0].exponent * P),
            Tail.Items);
    }
}

template MulDimension(A, B)
{
    alias MulDimension = Dimension!(A.TermsList.Items, B.TermsList.Items);
}

template DivDimension(A, B)
{
    alias NB = NegateTerms!(B.TermsList);
    alias DivDimension = Dimension!(A.TermsList.Items, NB.Items);
}

template PowDimension(A, int P)
{
    alias S = ScaleTerms!(A.TermsList, P);
    alias PowDimension = Dimension!(S.Items);
}

alias LengthDimension = Dimension!(DimTerm!(LengthTag, 1));
alias TimeDimension = Dimension!(DimTerm!(TimeTag, 1));

// ----- Unit algebra -----

struct Unit(DimensionT, RatioT)
{
    alias Dimension = DimensionT;
    alias Scale = RatioT;
}

template MulUnit(A, B)
{
    alias MulUnit = Unit!(
        MulDimension!(A.Dimension, B.Dimension),
        MulRatio!(A.Scale, B.Scale));
}

template DivUnit(A, B)
{
    alias DivUnit = Unit!(
        DivDimension!(A.Dimension, B.Dimension),
        DivRatio!(A.Scale, B.Scale));
}

template PowUnit(A, int P)
{
    alias PowUnit = Unit!(
        PowDimension!(A.Dimension, P),
        PowRatio!(A.Scale, P));
}

alias Metre = Unit!(LengthDimension, ExactRatio!(1, 1));
alias Millimetre = Unit!(LengthDimension, ExactRatio!(1, 1000));
alias Kilometre = Unit!(LengthDimension, ExactRatio!(1000, 1));
alias Second = Unit!(TimeDimension, ExactRatio!(1, 1));
alias Hour = Unit!(TimeDimension, ExactRatio!(3600, 1));

alias SquareMetre = PowUnit!(Metre, 2);
alias SquareMillimetre = PowUnit!(Millimetre, 2);
alias SquareKilometre = PowUnit!(Kilometre, 2);

static assert(is(
    SquareMetre.Dimension ==
    PowDimension!(LengthDimension, 2)));
static assert(SquareMetre.Scale.numerator == 1);
static assert(SquareMetre.Scale.denominator == 1);

static assert(SquareMillimetre.Scale.numerator == 1);
static assert(SquareMillimetre.Scale.denominator == 1_000_000);

static assert(SquareKilometre.Scale.numerator == 1_000_000);
static assert(SquareKilometre.Scale.denominator == 1);

alias MetresPerSecond = DivUnit!(Metre, Second);
alias KilometresPerHour = DivUnit!(Kilometre, Hour);

static assert(is(
    MetresPerSecond.Dimension ==
    DivDimension!(LengthDimension, TimeDimension)));
static assert(KilometresPerHour.Scale.numerator == 5);
static assert(KilometresPerHour.Scale.denominator == 18);

alias MetresPerSecondSquared = DivUnit!(MetresPerSecond, Second);
alias KilometresPerSecondSquared = DivUnit!(Kilometre, PowUnit!(Second, 2));

static assert(is(
    MetresPerSecondSquared.Dimension ==
    DivDimension!(
        LengthDimension,
        PowDimension!(TimeDimension, 2))));
static assert(MetresPerSecondSquared.Scale.numerator == 1);
static assert(MetresPerSecondSquared.Scale.denominator == 1);

static assert(KilometresPerSecondSquared.Scale.numerator == 1000);
static assert(KilometresPerSecondSquared.Scale.denominator == 1);

// Algebraic unit identities.
static assert(is(MulUnit!(Metre, Metre).Dimension == SquareMetre.Dimension));
static assert(MulUnit!(Metre, Metre).Scale.numerator == 1);
static assert(is(DivUnit!(SquareMetre, Metre).Dimension == Metre.Dimension));
static assert(DivUnit!(SquareMetre, Metre).Scale.numerator == 1);

// Reciprocal powers.
alias PerSecond = PowUnit!(Second, -1);
static assert(is(
    PerSecond.Dimension ==
    PowDimension!(TimeDimension, -1)));
static assert(PerSecond.Scale.numerator == 1);
static assert(PerSecond.Scale.denominator == 1);

void main()
{
    import std.stdio : writeln;
    writeln("PASS: unit algebra probe");
}
