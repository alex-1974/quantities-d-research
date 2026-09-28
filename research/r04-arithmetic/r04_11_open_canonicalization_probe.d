module r04_11_open_canonicalization_probe;

import std.meta : AliasSeq;

// R04.11 research: can an open dimension model canonicalize without a
// core-owned global TagRank table?

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

// --------------------------------------------------------------------------
// Strategy A: self-described stable tag key.
//
// The core does not own a registry. Each independent dimension tag supplies a
// stable compile-time key. Consumers can add tags without editing quantities-d.
// --------------------------------------------------------------------------

struct LengthTag { enum dimensionKey = "si:length"; }
struct TimeTag { enum dimensionKey = "si:time"; }
struct ConsumerAxisTag { enum dimensionKey = "consumer:axis"; }

template tagLess(A, B)
{
    enum tagLess = A.dimensionKey < B.dimensionKey;
}

template InsertSorted(List, Term)
{
    static if (List.length == 0)
        alias InsertSorted = TermList!Term;
    else
    {
        alias Head = List.Items[0];
        static if (is(Head.DimensionTag == Term.DimensionTag))
        {
            enum e = Head.exponent + Term.exponent;
            static if (e == 0)
                alias InsertSorted = TermList!(List.Items[1 .. $]);
            else
                alias InsertSorted = TermList!(
                    DimTerm!(Head.DimensionTag, e),
                    List.Items[1 .. $]);
        }
        else static if (tagLess!(Term.DimensionTag, Head.DimensionTag))
            alias InsertSorted = TermList!(Term, List.Items);
        else
            alias InsertSorted = TermList!(
                Head,
                InsertSorted!(
                    TermList!(List.Items[1 .. $]),
                    Term).Items);
    }
}

template Normalize(Terms...)
{
    static if (Terms.length == 0)
        alias Normalize = TermList!();
    else
        alias Normalize = InsertSorted!(
            Normalize!(Terms[1 .. $]),
            Terms[0]);
}

struct CanonicalDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

template KeyedDimension(Terms...)
{
    alias N = Normalize!Terms;
    alias KeyedDimension = CanonicalDimension!(N.Items);
}

template KeyedMul(A, B)
{
    alias KeyedMul = KeyedDimension!(
        A.TermsList.Items,
        B.TermsList.Items);
}

alias KA = KeyedDimension!(
    DimTerm!(LengthTag, 1),
    DimTerm!(TimeTag, -1));

alias KB = KeyedDimension!(
    DimTerm!(TimeTag, -1),
    DimTerm!(LengthTag, 1));

// Canonicalization must occur before the concrete dimension type is formed.
static assert(is(KA == KB));

alias KLength = KeyedDimension!(DimTerm!(LengthTag, 1));
alias KTime = KeyedDimension!(DimTerm!(TimeTag, 1));
alias KConsumer = KeyedDimension!(DimTerm!(ConsumerAxisTag, 1));

static assert(is(
    KeyedMul!(KLength, KConsumer) ==
    KeyedMul!(KConsumer, KLength)));

// --------------------------------------------------------------------------
// Strategy B: order-insensitive semantic equality.
//
// This allows arbitrary storage order, but type identity is no longer enough:
// two mathematically equal dimensions can be distinct D types.
// --------------------------------------------------------------------------

struct UnorderedDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

template exponentOf(D, Tag)
{
    enum exponentOf = exponentOfList!(D.TermsList, Tag);
}

template exponentOfList(List, Tag)
{
    static if (List.length == 0)
        enum exponentOfList = 0;
    else static if (is(List.Items[0].DimensionTag == Tag))
        enum exponentOfList =
            List.Items[0].exponent +
            exponentOfList!(TermList!(List.Items[1 .. $]), Tag);
    else
        enum exponentOfList =
            exponentOfList!(TermList!(List.Items[1 .. $]), Tag);
}

template allTermsMatch(AList, A, B)
{
    static if (AList.length == 0)
        enum allTermsMatch = true;
    else
    {
        alias Tag = AList.Items[0].DimensionTag;
        enum allTermsMatch =
            exponentOf!(A, Tag) == exponentOf!(B, Tag) &&
            allTermsMatch!(
                TermList!(AList.Items[1 .. $]), A, B);
    }
}

template SameDimension(A, B)
{
    enum SameDimension =
        allTermsMatch!(A.TermsList, A, B) &&
        allTermsMatch!(B.TermsList, A, B);
}

alias UA = UnorderedDimension!(
    DimTerm!(LengthTag, 1),
    DimTerm!(TimeTag, -1));

alias UB = UnorderedDimension!(
    DimTerm!(TimeTag, -1),
    DimTerm!(LengthTag, 1));

static assert(!is(UA == UB));
static assert(SameDimension!(UA, UB));

// This is the architectural trade-off:
// keyed normalization preserves native D type identity;
// unordered storage avoids ordering policy but requires semantic equality
// everywhere dimensions are compared.
