module r04_11_negative_conflict;

import r04_11_probe;

struct LeftResult
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

struct RightResult
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

struct ConflictLeft
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductWith(Rhs)
    {
        static if (is(Rhs == ConflictRight))
            alias ProductWith = LeftResult;
        else
            alias ProductWith = void;
    }
}

struct ConflictRight
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductFromLeft(Lhs)
    {
        static if (is(Lhs == ConflictLeft))
            alias ProductFromLeft = RightResult;
        else
            alias ProductFromLeft = void;
    }
}

// MUST fail: both operands claim the relation but disagree on ResultSpec.
alias MustFail = MulResult!(ConflictLeft, ConflictRight);
