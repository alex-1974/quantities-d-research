module r04_11_consumer_probe;

import r04_11_probe;

// Simulates a type owned by quantities-d which has no knowledge of this module.
struct ExistingExternalSpec
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

// Consumer owns only the RHS and result Specs.
struct ConsumerExternalArea
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareKilometre;
}

struct ConsumerExternalRhs
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductFromLeft(Lhs)
    {
        static if (is(Lhs == ExistingExternalSpec))
            alias ProductFromLeft = ConsumerExternalArea;
        else
            alias ProductFromLeft = void;
    }
}

alias ExternalModel = ProductModel!(ExistingExternalSpec, ConsumerExternalRhs);

static assert(is(ExternalModel.ResultSpec == ConsumerExternalArea));
static assert(ExternalModel.Rescale.numerator == 1);
static assert(ExternalModel.Rescale.denominator == 1_000_000);
