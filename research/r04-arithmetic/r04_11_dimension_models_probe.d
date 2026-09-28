module r04_11_dimension_models_probe;

import std.meta : AliasSeq;

// R04.11 research: compare dimension representation families.
// This module intentionally does not choose a production representation.

// --------------------------------------------------------------------------
// Model A: fixed exponent vector (small representative L/T/M subset).
// --------------------------------------------------------------------------

struct FixedDimension(int L, int T, int M)
{
    enum length = L;
    enum time = T;
    enum mass = M;
}

template FixedMul(A, B)
{
    alias FixedMul = FixedDimension!(
        A.length + B.length,
        A.time + B.time,
        A.mass + B.mass);
}

template FixedDiv(A, B)
{
    alias FixedDiv = FixedDimension!(
        A.length - B.length,
        A.time - B.time,
        A.mass - B.mass);
}

template FixedPow(A, int N)
{
    alias FixedPow = FixedDimension!(
        A.length * N,
        A.time * N,
        A.mass * N);
}

alias FixedLength = FixedDimension!(1, 0, 0);
alias FixedTime = FixedDimension!(0, 1, 0);
alias FixedMass = FixedDimension!(0, 0, 1);

static assert(is(FixedMul!(FixedLength, FixedLength) ==
                 FixedDimension!(2, 0, 0)));
static assert(is(FixedDiv!(FixedLength, FixedTime) ==
                 FixedDimension!(1, -1, 0)));
static assert(is(FixedPow!(FixedTime, -2) ==
                 FixedDimension!(0, -2, 0)));

// --------------------------------------------------------------------------
// Model B: open tag/exponent terms.
//
// Canonical equality requires normalization. For this first probe we keep the
// representation sorted by an explicit tag order and merge equal tags.
// --------------------------------------------------------------------------

struct LengthTag {}
struct TimeTag {}
struct MassTag {}
struct InformationTag {}
struct ConsumerAxisTag {}

template DimTerm(Tag, int Exponent)
{
    alias DimensionTag = Tag;
    enum exponent = Exponent;
}

template TagRank(Tag)
{
    static if (is(Tag == LengthTag)) enum TagRank = 10;
    else static if (is(Tag == TimeTag)) enum TagRank = 20;
    else static if (is(Tag == MassTag)) enum TagRank = 30;
    else static if (is(Tag == InformationTag)) enum TagRank = 40;
    else static if (is(Tag == ConsumerAxisTag)) enum TagRank = 1000;
    else static assert(0, "unranked dimension tag in research probe");
}

struct TermList(Terms...)
{
    alias Items = AliasSeq!Terms;
    enum length = Terms.length;
}

struct OpenDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

template MergeTermLists(AList, BList)
{
    // Focused merge for already-sorted typelists. Zero exponents disappear.
    static if (AList.length == 0)
        alias MergeTermLists = BList;
    else static if (BList.length == 0)
        alias MergeTermLists = AList;
    else
    {
        alias A = AList[0];
        alias B = BList[0];

        static if (TagRank!(A.DimensionTag) < TagRank!(B.DimensionTag))
            alias MergeTermLists = AliasSeq!(A,
                MergeTermLists!(AList[1 .. $], BList));
        else static if (TagRank!(A.DimensionTag) > TagRank!(B.DimensionTag))
            alias MergeTermLists = AliasSeq!(B,
                MergeTermLists!(AList, BList[1 .. $]));
        else
        {
            enum sum = A.exponent + B.exponent;
            static if (sum == 0)
                alias MergeTermLists =
                    MergeTermLists!(AList[1 .. $], BList[1 .. $]);
            else
                alias MergeTermLists = AliasSeq!(
                    DimTerm!(A.DimensionTag, sum),
                    MergeTermLists!(AList[1 .. $], BList[1 .. $]));
        }
    }
}

template NegateTerms(List)
{
    static if (List.length == 0)
        alias NegateTerms = AliasSeq!();
    else
        alias NegateTerms = AliasSeq!(
            DimTerm!(List[0].DimensionTag, -List[0].exponent),
            NegateTerms!(List[1 .. $]));
}

template ScaleTerms(List, int N)
{
    static if (List.length == 0)
        alias ScaleTerms = AliasSeq!();
    else static if (List[0].exponent * N == 0)
        alias ScaleTerms = ScaleTerms!(List[1 .. $], N);
    else
        alias ScaleTerms = AliasSeq!(
            DimTerm!(List[0].DimensionTag, List[0].exponent * N),
            ScaleTerms!(List[1 .. $], N));
}

template OpenMul(A, B)
{
    alias OpenMul = OpenDimension!(
        MergeTermLists!(A.TermsList, B.TermsList).Items);
}

template OpenDiv(A, B)
{
    alias OpenDiv = OpenDimension!(
        MergeTermLists!(A.TermsList, NegateTerms!(B.TermsList)).Items);
}

template OpenPow(A, int N)
{
    alias OpenPow = OpenDimension!(ScaleTerms!(A.TermsList, N).Items);
}

alias OpenLength = OpenDimension!(DimTerm!(LengthTag, 1));
alias OpenTime = OpenDimension!(DimTerm!(TimeTag, 1));
alias OpenMass = OpenDimension!(DimTerm!(MassTag, 1));
alias OpenConsumerAxis =
    OpenDimension!(DimTerm!(ConsumerAxisTag, 1));

alias OpenVelocity = OpenDiv!(OpenLength, OpenTime);
alias OpenAcceleration = OpenDiv!(OpenVelocity, OpenTime);
alias OpenArea = OpenPow!(OpenLength, 2);

static assert(OpenArea.TermsList.length == 1);
static assert(OpenArea.TermsList.Items[0].exponent == 2);
static assert(OpenAcceleration.TermsList.length == 2);
static assert(OpenAcceleration.TermsList.Items[0].exponent == 1);
static assert(OpenAcceleration.TermsList.Items[1].exponent == -2);

// Cancellation must normalize to the empty dimension.
alias OpenDimensionless = OpenDiv!(OpenLength, OpenLength);
static assert(OpenDimensionless.TermsList.length == 0);

// Consumer-defined independent axis can participate without changing the
// dimension container itself. The ranking mechanism is deliberately exposed
// here as the weak point: a truly open model cannot require core-owned ranks.
alias OpenExtended = OpenMul!(OpenLength, OpenConsumerAxis);
static assert(OpenExtended.TermsList.length == 2);

// --------------------------------------------------------------------------
// Model C: hybrid.
//
// Fixed SI-like core plus a separate extension list. This keeps common
// operations cheap but still needs normalization/equality rules for extensions,
// and algebra must operate over two representations at once.
// --------------------------------------------------------------------------

template HybridDimension(int L, int T, int M, Extensions...)
{
    enum length = L;
    enum time = T;
    enum mass = M;
    alias ExtensionTerms = AliasSeq!Extensions;
}

alias HybridLength = HybridDimension!(1, 0, 0);
alias HybridConsumerAxis =
    HybridDimension!(0, 0, 0, DimTerm!(ConsumerAxisTag, 1));

// This compile-only probe intentionally stops short of implementing complete
// Hybrid algebra. Its purpose is to make the architectural cost explicit:
// every operation needs both fixed-vector arithmetic and normalized extension
// arithmetic, and equality/canonicalization spans both halves.

static assert(HybridLength.ExtensionTerms.length == 0);
static assert(HybridConsumerAxis.ExtensionTerms.length == 1);
