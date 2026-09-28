module r04_13_quotient_semantic_resolver_probe;

// R04.13 probe 1: quotient Spec algebra only.
//
// This probe deliberately excludes Quantity values, Rep arithmetic and Unit
// scaling. It asks only whether ordered quotient semantics can be resolved
// without deriving semantic meaning from physical Dimension alone.

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

template QuotientResultSpec(Lhs, Rhs)
{
    alias Forward = ForwardQuotient!(Lhs, Rhs);
    alias Reverse = ReverseQuotient!(Lhs, Rhs);

    static if (!is(Forward == void) && !is(Reverse == void))
        static assert(is(Forward == Reverse),
            "conflicting Quantity quotient semantic relations");

    static if (!is(Forward == void))
        alias QuotientResultSpec = Forward;
    else
        alias QuotientResultSpec = Reverse;
}

private template ExternalQuotient(alias Relations, Lhs, Rhs)
{
    static if (__traits(hasMember, Relations, "Quotient"))
        alias ExternalQuotient = Relations.Quotient!(Lhs, Rhs);
    else
        alias ExternalQuotient = void;
}

// Explicit providers are authoritative: no fallback to operand-owned hooks.
template ExternalQuotientResultSpec(alias Relations, Lhs, Rhs)
{
    alias ExternalQuotientResultSpec = ExternalQuotient!(Relations, Lhs, Rhs);
}

struct RatioSpec {}
struct LengthSpec {}
struct VelocitySpec {}
struct ReciprocalLengthSpec {}

struct Length
{
    template QuotientWith(Rhs)
    {
        static if (is(Rhs == Length))
            alias QuotientWith = RatioSpec;
        else
            alias QuotientWith = void;
    }
}

static assert(is(QuotientResultSpec!(Length, Length) == RatioSpec));

struct Area {}

struct LengthAsDivisor
{
    template QuotientFromLeft(Lhs)
    {
        static if (is(Lhs == Area))
            alias QuotientFromLeft = LengthSpec;
        else
            alias QuotientFromLeft = void;
    }
}

static assert(is(
    QuotientResultSpec!(Area, LengthAsDivisor) == LengthSpec));

struct Unknown {}
static assert(is(QuotientResultSpec!(Unknown, Unknown) == void));

struct ConflictA {}
struct ConflictB {}

struct ConflictLeft
{
    template QuotientWith(Rhs)
    {
        alias QuotientWith = ConflictA;
    }
}

struct ConflictRight
{
    template QuotientFromLeft(Lhs)
    {
        alias QuotientFromLeft = ConflictB;
    }
}

static assert(!__traits(compiles,
{
    alias X = QuotientResultSpec!(ConflictLeft, ConflictRight);
}));

struct ForeignLength {}
struct ForeignTime {}
struct ForeignArea {}

struct ConsumerRelations
{
    template Quotient(Lhs, Rhs)
    {
        static if (is(Lhs == ForeignLength) && is(Rhs == ForeignTime))
            alias Quotient = VelocitySpec;
        else static if (is(Lhs == ForeignLength) && is(Rhs == ForeignArea))
            alias Quotient = ReciprocalLengthSpec;
        else
            alias Quotient = void;
    }
}

static assert(is(ExternalQuotientResultSpec!(
    ConsumerRelations, ForeignLength, ForeignTime) == VelocitySpec));
static assert(is(ExternalQuotientResultSpec!(
    ConsumerRelations, ForeignLength, ForeignArea) == ReciprocalLengthSpec));
static assert(is(ExternalQuotientResultSpec!(
    ConsumerRelations, ForeignTime, ForeignLength) == void));

// Ordered semantics: defining Lhs/Rhs says nothing about Rhs/Lhs.
static assert(is(ExternalQuotientResultSpec!(
    ConsumerRelations, ForeignLength, ForeignTime) == VelocitySpec));
static assert(is(ExternalQuotientResultSpec!(
    ConsumerRelations, ForeignTime, ForeignLength) == void));

// Authoritative external provider: an absent external relation does not fall
// back to an operand-owned relation.
struct NoExternalRelations
{
    template Quotient(Lhs, Rhs)
    {
        alias Quotient = void;
    }
}

static assert(is(QuotientResultSpec!(Length, Length) == RatioSpec));
static assert(is(ExternalQuotientResultSpec!(
    NoExternalRelations, Length, Length) == void));

void main() {}
