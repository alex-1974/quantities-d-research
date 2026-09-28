module r04_12_external_product_relation_probe;

// Probe: explicit consumer-owned product relations for Specs that cannot be
// modified by the consumer. No global registry and no central relation table.

private template MemberProduct(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "ProductWith"))
        alias MemberProduct = Lhs.ProductWith!Rhs;
    else
        alias MemberProduct = void;
}

private template ReverseProduct(Lhs, Rhs)
{
    static if (__traits(hasMember, Rhs, "ProductFromLeft"))
        alias ReverseProduct = Rhs.ProductFromLeft!Lhs;
    else
        alias ReverseProduct = void;
}

struct NoProductRelations
{
    template Product(Lhs, Rhs)
    {
        alias Product = void;
    }
}

private template ExternalProduct(alias Relations, Lhs, Rhs)
{
    static if (__traits(hasMember, Relations, "Product"))
        alias ExternalProduct = Relations.Product!(Lhs, Rhs);
    else
        alias ExternalProduct = void;
}

template ResolveProduct(alias Relations, Lhs, Rhs)
{
    alias Forward = MemberProduct!(Lhs, Rhs);
    alias Reverse = ReverseProduct!(Lhs, Rhs);
    alias External = ExternalProduct!(Relations, Lhs, Rhs);

    static if (!is(Forward == void) && !is(Reverse == void))
        static assert(is(Forward == Reverse),
            "conflicting member product relations");

    static if (!is(Forward == void))
        alias Owned = Forward;
    else
        alias Owned = Reverse;

    static if (!is(Owned == void) && !is(External == void))
    {
        static assert(is(Owned == External),
            "external product relation conflicts with operand-owned relation");
        alias ResolveProduct = Owned;
    }
    else static if (!is(Owned == void))
        alias ResolveProduct = Owned;
    else
        alias ResolveProduct = External;
}

struct ForeignLength {}
struct ForeignTime {}
struct ForeignVelocity {}

struct ConsumerRelations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == ForeignLength) && is(Rhs == ForeignTime))
            alias Product = ForeignVelocity;
        else
            alias Product = void;
    }
}

static assert(is(ResolveProduct!(
    ConsumerRelations, ForeignLength, ForeignTime) == ForeignVelocity));
static assert(is(ResolveProduct!(
    NoProductRelations, ForeignLength, ForeignTime) == void));

struct OwnedResult {}
struct ConflictingResult {}

struct OwnedLeft
{
    template ProductWith(Rhs)
    {
        static if (is(Rhs == ForeignTime))
            alias ProductWith = OwnedResult;
        else
            alias ProductWith = void;
    }
}

struct AgreeingRelations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == OwnedLeft) && is(Rhs == ForeignTime))
            alias Product = OwnedResult;
        else
            alias Product = void;
    }
}

struct ConflictingRelations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == OwnedLeft) && is(Rhs == ForeignTime))
            alias Product = ConflictingResult;
        else
            alias Product = void;
    }
}

static assert(is(ResolveProduct!(
    AgreeingRelations, OwnedLeft, ForeignTime) == OwnedResult));

static assert(!__traits(compiles,
{
    alias X = ResolveProduct!(
        ConflictingRelations, OwnedLeft, ForeignTime);
}));

// An operation can carry the relation provider explicitly. This is the key
// escape hatch for two foreign Specs; ordinary operator overloads continue
// using only operand-owned relations because D operators have no place for
// an extra relation-provider template argument.
auto explicitProduct(alias Relations, Lhs, Rhs)(Lhs lhs, Rhs rhs)
{
    alias Result = ResolveProduct!(Relations, Lhs, Rhs);
    static assert(!is(Result == void), "no product semantic relation");
    return Result.init;
}

static assert(is(typeof(explicitProduct!ConsumerRelations(
    ForeignLength.init, ForeignTime.init)) == ForeignVelocity));

void main() {}
