module r04_11_relation_api_probe;

import r04_11_probe;
import r04_11_third_customization_probe;

// This probe compares two API shapes for making an explicit relation set
// available without adding it to Quantity!(Spec, Rep).

struct MockQuantity(Spec, Rep)
{
    Rep value;
}

// Candidate A: named operation.
//
// The relation set is explicit at the call site and never becomes part of the
// quantity type.
auto multiplyWith(Relations, LhsSpec, LhsRep, RhsSpec, RhsRep)(
    MockQuantity!(LhsSpec, LhsRep) lhs,
    MockQuantity!(RhsSpec, RhsRep) rhs)
{
    alias ResultSpec =
        MulResultWith!(Relations, LhsSpec, RhsSpec);

    static assert(!is(ResultSpec == void));

    // Arithmetic is deliberately minimal here; this probe is about how the
    // semantic customization reaches the operation.
    return MockQuantity!(ResultSpec, long)(
        cast(long) lhs.value * cast(long) rhs.value);
}

unittest
{
    auto a = MockQuantity!(LibraryASpec, int)(3);
    auto b = MockQuantity!(LibraryBSpec, int)(4);

    auto result = multiplyWith!ConsumerRelations(a, b);
    static assert(is(typeof(result) == MockQuantity!(ConsumerResult, long)));
    assert(result.value == 12);
}

// Candidate B: zero-state relation scope wrapper.
//
// The wrapper carries the relation-set TYPE only at compile time. It does not
// alter MockQuantity's type identity and need not store relation state.
struct WithRelations(Relations, Q)
{
    Q quantity;

    auto opBinary(string op, RhsQ)(WithRelations!(Relations, RhsQ) rhs)
        if (op == "*")
    {
        alias LhsSpec = typeof(quantity).SpecType;
        alias RhsSpec = typeof(rhs.quantity).SpecType;
        alias ResultSpec = MulResultWith!(Relations, LhsSpec, RhsSpec);
        static assert(!is(ResultSpec == void));

        return MockQuantity!(ResultSpec, long)(
            cast(long) quantity.value * cast(long) rhs.quantity.value);
    }
}

// Add aliases solely for the wrapper experiment.
struct WrappedQuantity(Spec, Rep)
{
    alias SpecType = Spec;
    Rep value;
}

struct RelationScope(Relations)
{
    auto wrap(Spec, Rep)(WrappedQuantity!(Spec, Rep) q)
    {
        return RelationWrapped!(Relations, Spec, Rep)(q);
    }
}

struct RelationWrapped(Relations, Spec, Rep)
{
    WrappedQuantity!(Spec, Rep) quantity;

    auto opBinary(string op, RhsSpec, RhsRep)(
        RelationWrapped!(Relations, RhsSpec, RhsRep) rhs)
        if (op == "*")
    {
        alias ResultSpec = MulResultWith!(Relations, Spec, RhsSpec);
        static assert(!is(ResultSpec == void));

        return WrappedQuantity!(ResultSpec, long)(
            cast(long) quantity.value * cast(long) rhs.quantity.value);
    }
}

unittest
{
    auto a = WrappedQuantity!(LibraryASpec, int)(3);
    auto b = WrappedQuantity!(LibraryBSpec, int)(4);

    RelationScope!ConsumerRelations relations;

    auto result = relations.wrap(a) * relations.wrap(b);
    static assert(is(typeof(result) ==
                     WrappedQuantity!(ConsumerResult, long)));
    assert(result.value == 12);
}
