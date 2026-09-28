module r04_12_exact_mul_relation_api_probe;

// API-shape probe only: compare explicit relation-provider syntax.
// Arithmetic is intentionally trivial here; the question is how a consumer
// supplies relations for two foreign operand Specs.

struct Left { int value; }
struct Right { int value; }
struct Result { int value; }

struct Relations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == Left) && is(Rhs == Right))
            alias Product = Result;
        else
            alias Product = void;
    }
}

private template Resolved(alias R, Lhs, Rhs)
{
    alias Resolved = R.Product!(Lhs, Rhs);
}

// A: overload the familiar operation name with Relations as template arg.
// UFCS: lhs.exactMul!Relations(rhs)
auto exactMul(alias R, Lhs, Rhs)(Lhs lhs, Rhs rhs)
{
    alias Out = Resolved!(R, Lhs, Rhs);
    static assert(!is(Out == void));
    return Out(lhs.value * rhs.value);
}

// B: separate explicit-provider operation name.
// UFCS: lhs.exactMulWith!Relations(rhs)
auto exactMulWith(alias R, Lhs, Rhs)(Lhs lhs, Rhs rhs)
{
    alias Out = Resolved!(R, Lhs, Rhs);
    static assert(!is(Out == void));
    return Out(lhs.value * rhs.value);
}

// C: bind a relation provider into a wrapper, then call an ordinary method.
// Syntax: withRelations!Relations(lhs).exactMul(rhs)
struct RelationBound(alias R, T)
{
    T value;

    auto exactMul(Rhs)(Rhs rhs)
    {
        alias Out = Resolved!(R, T, Rhs);
        static assert(!is(Out == void));
        return Out(value.value * rhs.value);
    }
}

auto withRelations(alias R, T)(T value)
{
    return RelationBound!(R, T)(value);
}

static assert(Left(3).exactMul!Relations(Right(4)).value == 12);
static assert(Left(3).exactMulWith!Relations(Right(4)).value == 12);
static assert(withRelations!Relations(Left(3)).exactMul(Right(4)).value == 12);

// The explicit provider is compile-time state only; wrapper carries only T.
static assert(RelationBound!(Relations, Left).sizeof == Left.sizeof);

void main() {}
