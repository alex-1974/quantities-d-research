module r04_12_exact_mul_overload_probe;

// Probe the intended production overload shape:
//   lhs.exactMul(rhs)            -> operand-owned semantic relation
//   lhs.exactMul!Relations(rhs)  -> explicit consumer-owned relation provider

struct OwnedResult { int value; }
struct ExternalResult { int value; }

struct OwnedLeft
{
    int value;

    template ProductWith(Rhs)
    {
        static if (is(Rhs == OwnedRight))
            alias ProductWith = OwnedResult;
        else
            alias ProductWith = void;
    }
}

struct OwnedRight { int value; }

struct ForeignLeft { int value; }
struct ForeignRight { int value; }

struct Relations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == ForeignLeft) && is(Rhs == ForeignRight))
            alias Product = ExternalResult;
        else
            alias Product = void;
    }
}

private template OwnedProduct(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "ProductWith"))
        alias OwnedProduct = Lhs.ProductWith!Rhs;
    else
        alias OwnedProduct = void;
}

private template ExternalProduct(alias R, Lhs, Rhs)
{
    alias ExternalProduct = R.Product!(Lhs, Rhs);
}

// Existing/default form.
auto exactMul(Lhs, Rhs)(Lhs lhs, Rhs rhs)
    if (!is(OwnedProduct!(Lhs, Rhs) == void))
{
    alias Out = OwnedProduct!(Lhs, Rhs);
    return Out(lhs.value * rhs.value);
}

// Candidate explicit-provider form.
auto exactMul(alias R, Lhs, Rhs)(Lhs lhs, Rhs rhs)
    if (!is(ExternalProduct!(R, Lhs, Rhs) == void))
{
    alias Out = ExternalProduct!(R, Lhs, Rhs);
    return Out(lhs.value * rhs.value);
}

enum owned = OwnedLeft(3).exactMul(OwnedRight(4));
static assert(is(typeof(owned) == OwnedResult));
static assert(owned.value == 12);

enum external = ForeignLeft(3).exactMul!Relations(ForeignRight(4));
static assert(is(typeof(external) == ExternalResult));
static assert(external.value == 12);

// The foreign pair has no accidental default relation.
static assert(!__traits(compiles,
    ForeignLeft(3).exactMul(ForeignRight(4))));

// Supplying an unrelated provider does not fall back silently to the owned
// relation. An explicit provider means "resolve through this provider".
static assert(!__traits(compiles,
    OwnedLeft(3).exactMul!Relations(OwnedRight(4))));

void main() {}
