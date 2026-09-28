module r04_11_canonical_dimension_algebra_probe;

import std.meta : AliasSeq;
import std.traits : fullyQualifiedName;

struct LengthTag {}
struct TimeTag {}
struct MassTag {}
struct ConsumerAxisTag {}

struct DimTerm(Tag, int Exponent)
{
    alias DimensionTag = Tag;
    enum exponent = Exponent;
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
        alias Tail = NegateTerms!(
            TermList!(List.Items[1 .. $]));
        alias NegateTerms = TermList!(
            DimTerm!(
                List.Items[0].DimensionTag,
                -List.Items[0].exponent),
            Tail.Items);
    }
}

template ScaleTerms(List, int Power)
{
    static if (List.length == 0)
        alias ScaleTerms = TermList!();
    else
    {
        alias Tail = ScaleTerms!(
            TermList!(List.Items[1 .. $]), Power);
        alias ScaleTerms = TermList!(
            DimTerm!(
                List.Items[0].DimensionTag,
                List.Items[0].exponent * Power),
            Tail.Items);
    }
}

template MulDimension(A, B)
{
    alias MulDimension = Dimension!(
        A.TermsList.Items,
        B.TermsList.Items);
}

template DivDimension(A, B)
{
    alias NegativeB = NegateTerms!(B.TermsList);
    alias DivDimension = Dimension!(
        A.TermsList.Items,
        NegativeB.Items);
}

template PowDimension(A, int Power)
{
    alias Scaled = ScaleTerms!(A.TermsList, Power);
    alias PowDimension = Dimension!(Scaled.Items);
}

alias Dimensionless = Dimension!();
alias Length = Dimension!(DimTerm!(LengthTag, 1));
alias Time = Dimension!(DimTerm!(TimeTag, 1));
alias Mass = Dimension!(DimTerm!(MassTag, 1));
alias ConsumerAxis = Dimension!(DimTerm!(ConsumerAxisTag, 1));

alias Area = PowDimension!(Length, 2);
alias Volume = PowDimension!(Length, 3);
alias Velocity = DivDimension!(Length, Time);
alias Acceleration = DivDimension!(Velocity, Time);
alias Force = MulDimension!(Mass, Acceleration);

static assert(is(
    Area ==
    Dimension!(DimTerm!(LengthTag, 2))));
static assert(is(
    Volume ==
    Dimension!(DimTerm!(LengthTag, 3))));
static assert(is(
    Velocity ==
    Dimension!(
        DimTerm!(LengthTag, 1),
        DimTerm!(TimeTag, -1))));
static assert(is(
    Acceleration ==
    Dimension!(
        DimTerm!(LengthTag, 1),
        DimTerm!(TimeTag, -2))));
static assert(is(
    Force ==
    Dimension!(
        DimTerm!(MassTag, 1),
        DimTerm!(LengthTag, 1),
        DimTerm!(TimeTag, -2))));

// Algebraic cancellation and neutral cases.
static assert(is(DivDimension!(Length, Length) == Dimensionless));
static assert(is(MulDimension!(Length, Dimensionless) == Length));
static assert(is(DivDimension!(Length, Dimensionless) == Length));
static assert(is(PowDimension!(Length, 0) == Dimensionless));
static assert(is(PowDimension!(Length, -1) ==
    Dimension!(DimTerm!(LengthTag, -1))));

// Canonicalization must make operand order irrelevant for multiplication.
static assert(is(
    MulDimension!(Length, Time) ==
    MulDimension!(Time, Length)));

// Repeated algebra must merge and remove zero exponents.
static assert(is(
    MulDimension!(Velocity, Time) ==
    Length));
static assert(is(
    DivDimension!(Area, Length) ==
    Length));

// Independent consumer-defined base axes participate without core registration.
static assert(is(
    MulDimension!(Length, ConsumerAxis) ==
    MulDimension!(ConsumerAxis, Length)));

void main()
{
    import std.stdio : writeln;
    writeln("PASS: canonical dimension algebra probe");
}
