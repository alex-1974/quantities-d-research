module r04_11_structural_dimension_probe;

import std.meta : AliasSeq;

// R04.11 research: compare canonical type identity with structural,
// compile-time-detected dimension semantics.

struct LengthTag {}
struct TimeTag {}
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

struct StructuralDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

// Detect the dimension protocol by compile-time structure rather than by
// nominal type identity.
template isDimensionLike(T)
{
    static if (!__traits(hasMember, T, "TermsList"))
        enum isDimensionLike = false;
    else static if (!__traits(hasMember, T.TermsList, "Items"))
        enum isDimensionLike = false;
    else
        enum isDimensionLike = true;
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

template sameDimension(A, B)
{
    static if (!isDimensionLike!A || !isDimensionLike!B)
        enum sameDimension = false;
    else
        enum sameDimension =
            allTermsMatch!(A.TermsList, A, B) &&
            allTermsMatch!(B.TermsList, A, B);
}

// Same mathematical dimension, intentionally different type argument order.
alias A = StructuralDimension!(
    DimTerm!(LengthTag, 1),
    DimTerm!(TimeTag, -1));

alias B = StructuralDimension!(
    DimTerm!(TimeTag, -1),
    DimTerm!(LengthTag, 1));

static assert(!is(A == B));
static assert(isDimensionLike!A);
static assert(isDimensionLike!B);
static assert(sameDimension!(A, B));

// Duplicate terms also collapse semantically.
alias C = StructuralDimension!(
    DimTerm!(LengthTag, 2),
    DimTerm!(LengthTag, -1),
    DimTerm!(TimeTag, -1));

static assert(sameDimension!(A, C));

// Independent consumer dimension is detected structurally without any core
// registry or inheritance.
alias ConsumerDim =
    StructuralDimension!(DimTerm!(ConsumerAxisTag, 1));

static assert(isDimensionLike!ConsumerDim);
static assert(!sameDimension!(A, ConsumerDim));

// A foreign type can participate if it deliberately exposes the same protocol.
struct ForeignDimension
{
    alias TermsList = TermList!(
        DimTerm!(TimeTag, -1),
        DimTerm!(LengthTag, 1));
}

static assert(isDimensionLike!ForeignDimension);
static assert(sameDimension!(A, ForeignDimension));

// This demonstrates the trade-off:
// - nominal/canonical type identity is cheapest once established;
// - structural equality is more open and protocol-based, but every equality
//   gate performs compile-time semantic work.
