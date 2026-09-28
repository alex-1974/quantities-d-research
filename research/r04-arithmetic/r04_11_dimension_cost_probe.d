module r04_11_dimension_cost_probe;

import std.meta : AliasSeq;

// R04.11 compile-time cost probe.
// Build with -version=NativeCost or -version=StructuralCost.
// DEPTH selects the number of independent dimension terms through version
// identifiers Cost1, Cost2, Cost4, Cost7. Default is 7.
// REPEAT is deliberately expressed by distinct wrapper instantiations so the
// compiler cannot satisfy the whole probe from one memoized query.

struct T0 {} struct T1 {} struct T2 {} struct T3 {}
struct T4 {} struct T5 {} struct T6 {}

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

struct Dimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

version (Cost1)
    alias A = Dimension!(DimTerm!(T0, 1));
else version (Cost2)
    alias A = Dimension!(DimTerm!(T0, 1), DimTerm!(T1, -1));
else version (Cost4)
    alias A = Dimension!(
        DimTerm!(T0, 1), DimTerm!(T1, -1),
        DimTerm!(T2, 2), DimTerm!(T3, -2));
else
    alias A = Dimension!(
        DimTerm!(T0, 1), DimTerm!(T1, -1),
        DimTerm!(T2, 2), DimTerm!(T3, -2),
        DimTerm!(T4, 3), DimTerm!(T5, -3),
        DimTerm!(T6, 1));

version (Cost1)
    alias B = Dimension!(DimTerm!(T0, 1));
else version (Cost2)
    alias B = Dimension!(DimTerm!(T1, -1), DimTerm!(T0, 1));
else version (Cost4)
    alias B = Dimension!(
        DimTerm!(T3, -2), DimTerm!(T2, 2),
        DimTerm!(T1, -1), DimTerm!(T0, 1));
else
    alias B = Dimension!(
        DimTerm!(T6, 1), DimTerm!(T5, -3),
        DimTerm!(T4, 3), DimTerm!(T3, -2),
        DimTerm!(T2, 2), DimTerm!(T1, -1),
        DimTerm!(T0, 1));

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

template exponentOf(D, Tag)
{
    enum exponentOf = exponentOfList!(D.TermsList, Tag);
}

template allTermsMatch(List, X, Y)
{
    static if (List.length == 0)
        enum allTermsMatch = true;
    else
    {
        alias Tag = List.Items[0].DimensionTag;
        enum allTermsMatch =
            exponentOf!(X, Tag) == exponentOf!(Y, Tag) &&
            allTermsMatch!(TermList!(List.Items[1 .. $]), X, Y);
    }
}

template sameDimension(X, Y)
{
    enum sameDimension =
        allTermsMatch!(X.TermsList, X, Y) &&
        allTermsMatch!(Y.TermsList, X, Y);
}

// Make every query use distinct dimension types so compiler memoization cannot
// collapse the benchmark to one semantic comparison. The extra marker exponent
// is identical on both sides of a query and therefore does not change whether
// the compared dimensions are mathematically equal.
struct QueryTag(size_t N) {}

template NativeDimension(size_t N)
{
    alias NativeDimension = Dimension!(
        A.TermsList.Items,
        DimTerm!(QueryTag!N, 1));
}

template StructuralLeft(size_t N)
{
    alias StructuralLeft = Dimension!(
        A.TermsList.Items,
        DimTerm!(QueryTag!N, 1));
}

template StructuralRight(size_t N)
{
    alias StructuralRight = Dimension!(
        DimTerm!(QueryTag!N, 1),
        B.TermsList.Items);
}

template NativeQuery(size_t N)
{
    alias D = NativeDimension!N;
    enum NativeQuery = is(D == D);
}

template StructuralQuery(size_t N)
{
    enum StructuralQuery =
        sameDimension!(StructuralLeft!N, StructuralRight!N);
}

enum queryCount = 4096;

version (NativeCost)
{
    static foreach (i; 0 .. queryCount)
        static assert(NativeQuery!i);
}
else version (StructuralCost)
{
    static foreach (i; 0 .. queryCount)
        static assert(StructuralQuery!i);
}
else
{
    static assert(0,
        "select -version=NativeCost or -version=StructuralCost");
}
