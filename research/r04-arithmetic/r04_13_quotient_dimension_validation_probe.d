module r04_13_quotient_dimension_validation_probe;

import std.meta : AliasSeq;
import std.traits : fullyQualifiedName;

// Minimal research copy of the promoted canonical Dimension algebra. The probe
// tests quotient semantic validation, not a replacement Dimension design.

struct DimensionTerm(Tag, int Exponent)
{
    alias DimensionTag = Tag;
    enum exponent = Exponent;
}

private struct TermList(Terms...)
{
    alias items = AliasSeq!Terms;
    enum length = Terms.length;
}

private template tagKey(Tag)
{
    enum tagKey = fullyQualifiedName!Tag;
}

private template termLess(A, B)
{
    static if (is(A.DimensionTag == B.DimensionTag))
        enum termLess = false;
    else
        enum termLess = tagKey!(A.DimensionTag) < tagKey!(B.DimensionTag);
}

private template InsertCanonical(List, Term)
{
    static if (Term.exponent == 0)
        alias InsertCanonical = List;
    else static if (List.length == 0)
        alias InsertCanonical = TermList!Term;
    else static if (is(List.items[0].DimensionTag == Term.DimensionTag))
    {
        enum exponent = List.items[0].exponent + Term.exponent;
        static if (exponent == 0)
            alias InsertCanonical = TermList!(List.items[1 .. $]);
        else
            alias InsertCanonical = TermList!(
                DimensionTerm!(Term.DimensionTag, exponent),
                List.items[1 .. $]);
    }
    else static if (termLess!(Term, List.items[0]))
        alias InsertCanonical = TermList!(Term, List.items);
    else
    {
        alias tail = InsertCanonical!(
            TermList!(List.items[1 .. $]), Term);
        alias InsertCanonical = TermList!(List.items[0], tail.items);
    }
}

private template Normalize(Terms...)
{
    static if (Terms.length == 0)
        alias Normalize = TermList!();
    else
    {
        alias tail = Normalize!(Terms[1 .. $]);
        alias Normalize = InsertCanonical!(tail, Terms[0]);
    }
}

private struct CanonicalDimension(Terms...)
{
    private alias terms = TermList!Terms;
}

template Dimension(Terms...)
{
    alias normalized = Normalize!Terms;
    alias Dimension = CanonicalDimension!(normalized.items);
}

template BaseDimension(Tag)
{
    alias BaseDimension = Dimension!(DimensionTerm!(Tag, 1));
}

alias Dimensionless = Dimension!();

private template NegateTerms(List)
{
    static if (List.length == 0)
        alias NegateTerms = TermList!();
    else
    {
        alias tail = NegateTerms!(TermList!(List.items[1 .. $]));
        alias NegateTerms = TermList!(
            DimensionTerm!(
                List.items[0].DimensionTag,
                -List.items[0].exponent),
            tail.items);
    }
}

template DivideDimension(A, B)
{
    alias negativeB = NegateTerms!(B.terms);
    alias DivideDimension = Dimension!(A.terms.items, negativeB.items);
}

template PowerDimension(A, int Power)
{
    static if (A.terms.length == 0)
        alias PowerDimension = Dimensionless;
    else
    {
        // Sufficient for this probe's one-axis powers.
        alias PowerDimension = Dimension!(
            DimensionTerm!(
                A.terms.items[0].DimensionTag,
                A.terms.items[0].exponent * Power));
    }
}

struct LengthTag {}
struct TimeTag {}

alias LengthDimension = BaseDimension!LengthTag;
alias TimeDimension = BaseDimension!TimeTag;
alias AreaDimension = PowerDimension!(LengthDimension, 2);
alias ReciprocalLengthDimension = PowerDimension!(LengthDimension, -1);
alias VelocityDimension = DivideDimension!(LengthDimension, TimeDimension);

static assert(is(
    DivideDimension!(LengthDimension, LengthDimension) == Dimensionless));
static assert(is(
    DivideDimension!(AreaDimension, LengthDimension) == LengthDimension));
static assert(is(
    DivideDimension!(LengthDimension, AreaDimension) ==
    ReciprocalLengthDimension));
static assert(is(
    DivideDimension!(LengthDimension, TimeDimension) == VelocityDimension));

struct RatioSpec { alias Dimension = Dimensionless; }
struct LengthSpec { alias Dimension = LengthDimension; }
struct AreaSpec { alias Dimension = AreaDimension; }
struct TimeSpec { alias Dimension = TimeDimension; }
struct VelocitySpec { alias Dimension = VelocityDimension; }
struct ReciprocalLengthSpec { alias Dimension = ReciprocalLengthDimension; }
struct WrongSpec { alias Dimension = TimeDimension; }

private template ForwardQuotient(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "QuotientWith"))
        alias ForwardQuotient = Lhs.QuotientWith!Rhs;
    else
        alias ForwardQuotient = void;
}

private template ReverseQuotient(Lhs, Rhs)
{
    static if (__traits(hasMember, Rhs, "QuotientFromLeft"))
        alias ReverseQuotient = Rhs.QuotientFromLeft!Lhs;
    else
        alias ReverseQuotient = void;
}

template ValidatedQuotientResultSpec(Lhs, Rhs)
{
    alias Forward = ForwardQuotient!(Lhs, Rhs);
    alias Reverse = ReverseQuotient!(Lhs, Rhs);

    static if (!is(Forward == void) && !is(Reverse == void))
        static assert(is(Forward == Reverse),
            "conflicting Quantity quotient semantic relations");

    static if (!is(Forward == void))
        alias Candidate = Forward;
    else
        alias Candidate = Reverse;

    static if (is(Candidate == void))
        alias ValidatedQuotientResultSpec = void;
    else
    {
        static assert(__traits(hasMember, Candidate, "Dimension"),
            "Quantity quotient result must define Dimension");
        static assert(is(
            Candidate.Dimension ==
            DivideDimension!(Lhs.Dimension, Rhs.Dimension)),
            "Quantity quotient ResultSpec has the wrong physical Dimension.");
        alias ValidatedQuotientResultSpec = Candidate;
    }
}

struct Length
{
    alias Dimension = LengthDimension;

    template QuotientWith(Rhs)
    {
        static if (is(Rhs == Length))
            alias QuotientWith = RatioSpec;
        else static if (is(Rhs == Area))
            alias QuotientWith = ReciprocalLengthSpec;
        else static if (is(Rhs == Time))
            alias QuotientWith = VelocitySpec;
        else
            alias QuotientWith = void;
    }
}

struct Area
{
    alias Dimension = AreaDimension;

    template QuotientWith(Rhs)
    {
        static if (is(Rhs == Length))
            alias QuotientWith = LengthSpec;
        else
            alias QuotientWith = void;
    }
}

struct Time { alias Dimension = TimeDimension; }

static assert(is(
    ValidatedQuotientResultSpec!(Length, Length) == RatioSpec));
static assert(is(
    ValidatedQuotientResultSpec!(Area, Length) == LengthSpec));
static assert(is(
    ValidatedQuotientResultSpec!(Length, Area) == ReciprocalLengthSpec));
static assert(is(
    ValidatedQuotientResultSpec!(Length, Time) == VelocitySpec));

struct BadLength
{
    alias Dimension = LengthDimension;
    template QuotientWith(Rhs)
    {
        alias QuotientWith = WrongSpec;
    }
}

static assert(!__traits(compiles,
{
    alias X = ValidatedQuotientResultSpec!(BadLength, Length);
}));

void main() {}
