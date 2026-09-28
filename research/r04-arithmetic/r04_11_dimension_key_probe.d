module r04_11_dimension_key_probe;

import std.meta : AliasSeq;
import std.traits : fullyQualifiedName;

struct LengthTag {}
struct TimeTag {}
struct ConsumerAxisTag {}

struct ExplicitA { enum dimensionKey = "consumer:a"; }
struct ExplicitB { enum dimensionKey = "consumer:b"; }
struct CollisionA { enum dimensionKey = "collision"; }
struct CollisionB { enum dimensionKey = "collision"; }

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

// Candidate A: explicit public ordering key.
template explicitKey(Tag)
{
    static assert(__traits(hasMember, Tag, "dimensionKey"));
    enum explicitKey = Tag.dimensionKey;
}

// Candidate B: automatic compiler-visible qualified type name.
// This is tested as an ordering mechanism only. Tag identity remains nominal.
template automaticKey(Tag)
{
    enum automaticKey = fullyQualifiedName!Tag;
}

static assert(automaticKey!LengthTag.length != 0);
static assert(automaticKey!TimeTag.length != 0);
static assert(automaticKey!ConsumerAxisTag.length != 0);
static assert(automaticKey!LengthTag != automaticKey!TimeTag);
static assert(explicitKey!ExplicitA != explicitKey!ExplicitB);

// Key equality must never define mathematical tag identity.
static assert(explicitKey!CollisionA == explicitKey!CollisionB);
static assert(!is(CollisionA == CollisionB));

template keyLess(alias Key, A, B)
{
    enum a = Key!(A.DimensionTag);
    enum b = Key!(B.DimensionTag);

    static if (a == b)
    {
        // A collision is valid only when it is literally the same tag.
        static assert(is(A.DimensionTag == B.DimensionTag),
            "dimension ordering-key collision between distinct tags");
        enum keyLess = false;
    }
    else
        enum keyLess = a < b;
}

template InsertSorted(alias Key, List, Term)
{
    static if (List.length == 0)
        alias InsertSorted = TermList!Term;
    else static if (is(List.Items[0].DimensionTag == Term.DimensionTag))
    {
        enum sum = List.Items[0].exponent + Term.exponent;
        static if (sum == 0)
            alias InsertSorted = TermList!(List.Items[1 .. $]);
        else
            alias InsertSorted = TermList!(
                DimTerm!(Term.DimensionTag, sum),
                List.Items[1 .. $]);
    }
    else static if (keyLess!(Key, Term, List.Items[0]))
        alias InsertSorted = TermList!(Term, List.Items);
    else
    {
        alias Tail = InsertSorted!(
            Key,
            TermList!(List.Items[1 .. $]),
            Term);
        alias InsertSorted = TermList!(List.Items[0], Tail.Items);
    }
}

template Normalize(alias Key, Terms...)
{
    static if (Terms.length == 0)
        alias Normalize = TermList!();
    else
    {
        alias Tail = Normalize!(Key, Terms[1 .. $]);
        alias Normalize = InsertSorted!(Key, Tail, Terms[0]);
    }
}

struct CanonicalDimension(Terms...)
{
    alias TermsList = TermList!Terms;
}

template MakeDimension(alias Key, Terms...)
{
    alias N = Normalize!(Key, Terms);
    alias MakeDimension = CanonicalDimension!(N.Items);
}

// Automatic qualified-name ordering: no public key required from consumer.
alias AutoA = MakeDimension!(
    automaticKey,
    DimTerm!(LengthTag, 1),
    DimTerm!(TimeTag, -1),
    DimTerm!(ConsumerAxisTag, 2));

alias AutoB = MakeDimension!(
    automaticKey,
    DimTerm!(ConsumerAxisTag, 2),
    DimTerm!(TimeTag, -1),
    DimTerm!(LengthTag, 1));

static assert(is(AutoA == AutoB));

// Explicit keys also work.
alias ExplicitDimA = MakeDimension!(
    explicitKey,
    DimTerm!(ExplicitA, 1),
    DimTerm!(ExplicitB, -1));

alias ExplicitDimB = MakeDimension!(
    explicitKey,
    DimTerm!(ExplicitB, -1),
    DimTerm!(ExplicitA, 1));

static assert(is(ExplicitDimA == ExplicitDimB));

void main()
{
    import std.stdio : writeln;
    writeln("LengthTag key: ", automaticKey!LengthTag);
    writeln("ConsumerAxisTag key: ", automaticKey!ConsumerAxisTag);
    writeln("PASS: dimension ordering key probe");
}
