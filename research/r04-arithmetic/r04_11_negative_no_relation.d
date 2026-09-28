module r04_11_negative_no_relation;

import r04_11_probe;

struct ForeignA
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

struct ForeignB
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

// This file MUST fail to compile: equal dimensions alone are not a semantic
// multiplication relation.
alias MustFail = ProductModel!(ForeignA, ForeignB);
