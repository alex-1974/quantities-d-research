module r04_11_two_foreign_specs;

import r04_11_probe;

// Simulates two Specs supplied by independent libraries. The consumer owns
// neither and therefore cannot add member hooks to either type.
struct ForeignLeft
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

struct ForeignRight
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

// The current member-hook mechanism has no third customization location.
// Therefore this MUST remain void. This is an intentional capability probe,
// not a desired final property.
static assert(is(MulResult!(ForeignLeft, ForeignRight) == void));
