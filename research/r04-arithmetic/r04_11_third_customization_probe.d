module r04_11_third_customization_probe;

import r04_11_probe;

// Two operand Specs that simulate types owned by independent libraries.
struct LibraryASpec
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

struct LibraryBSpec
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

struct ConsumerResult
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

// Candidate A: a free customization template in the consumer module.
//
// The important question is lookup, not whether this template can express the
// relation. A core template defined in another module cannot in general
// discover arbitrary declarations introduced later by an importing module.
template ConsumerProductResult(Lhs, Rhs)
{
    static if (is(Lhs == LibraryASpec) && is(Rhs == LibraryBSpec))
        alias ConsumerProductResult = ConsumerResult;
    else
        alias ConsumerProductResult = void;
}

// Candidate B: explicit compile-time relation set.
//
// The consumer owns the relation object, while Quantity itself remains
// Quantity!(Spec, Rep). The relation set is supplied to the arithmetic
// operation/resolver, not stored in either Quantity type.
struct ConsumerRelations
{
    template ProductResult(Lhs, Rhs)
    {
        static if (is(Lhs == LibraryASpec) && is(Rhs == LibraryBSpec))
            alias ProductResult = ConsumerResult;
        else
            alias ProductResult = void;
    }
}

template MulResultWith(Relations, Lhs, Rhs)
{
    alias ExternalCandidate = Relations.ProductResult!(Lhs, Rhs);

    static if (!is(ExternalCandidate == void))
        alias MulResultWith = ExternalCandidate;
    else
        alias MulResultWith = MulResult!(Lhs, Rhs);
}

static assert(is(MulResult!(LibraryASpec, LibraryBSpec) == void));
static assert(is(MulResultWith!(ConsumerRelations, LibraryASpec, LibraryBSpec)
                 == ConsumerResult));

alias ExternalModel = ProductModel!(
    LibraryASpec,
    LibraryBSpec,
    MulResultWith!(ConsumerRelations, LibraryASpec, LibraryBSpec));

static assert(is(ExternalModel.ResultSpec == ConsumerResult));
static assert(ExternalModel.Rescale.numerator == 1);
static assert(ExternalModel.Rescale.denominator == 1);
