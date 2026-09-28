module r04_11_probe;

// Research-only compile-time model. No production API decision.

// --- Exact scale -----------------------------------------------------------

struct Ratio(long N, long D)
{
    static assert(D != 0);
    enum numerator = N;
    enum denominator = D;
}

template MulRatio(A, B)
{
    alias MulRatio = Ratio!(
        A.numerator * B.numerator,
        A.denominator * B.denominator);
}

template DivRatio(A, B)
{
    alias DivRatio = Ratio!(
        A.numerator * B.denominator,
        A.denominator * B.numerator);
}

// --- Minimal dimension algebra: L^l T^t -----------------------------------

struct Dimension(int L, int T) {}

template MulDimension(A, B)
{
    alias MulDimension = Dimension!(
        A.tupleof[0] + B.tupleof[0],
        A.tupleof[1] + B.tupleof[1]);
}

template DivDimension(A, B)
{
    alias DivDimension = Dimension!(
        A.tupleof[0] - B.tupleof[0],
        A.tupleof[1] - B.tupleof[1]);
}

alias LengthDimension       = Dimension!(1, 0);
alias TimeDimension         = Dimension!(0, 1);
alias AreaDimension         = Dimension!(2, 0);
alias VelocityDimension     = Dimension!(1, -1);
alias AccelerationDimension = Dimension!(1, -2);

// --- Unit algebra ----------------------------------------------------------

struct Unit(Dimension, Scale)
{
    alias DimensionType = Dimension;
    alias ScaleType = Scale;
}

alias Metre      = Unit!(LengthDimension, Ratio!(1, 1));
alias Millimetre = Unit!(LengthDimension, Ratio!(1, 1000));
alias Kilometre  = Unit!(LengthDimension, Ratio!(1000, 1));
alias Second     = Unit!(TimeDimension, Ratio!(1, 1));
alias Hour       = Unit!(TimeDimension, Ratio!(3600, 1));

template MulUnit(A, B)
{
    alias MulUnit = Unit!(
        MulDimension!(A.DimensionType, B.DimensionType),
        MulRatio!(A.ScaleType, B.ScaleType));
}

template DivUnit(A, B)
{
    alias DivUnit = Unit!(
        DivDimension!(A.DimensionType, B.DimensionType),
        DivRatio!(A.ScaleType, B.ScaleType));
}

alias SquareMetre = MulUnit!(Metre, Metre);
alias SquareMillimetre = MulUnit!(Millimetre, Millimetre);
alias SquareKilometre = MulUnit!(Kilometre, Kilometre);
alias MetresPerSecond = DivUnit!(Metre, Second);
alias KilometresPerHour = DivUnit!(Kilometre, Hour);
alias MetresPerSecondSquared = DivUnit!(MetresPerSecond, Second);
alias KilometresPerSecondSquared = DivUnit!(Kilometre, MulUnit!(Second, Second));

// --- Specs ----------------------------------------------------------------

struct Area;
struct Velocity;
struct Acceleration;

struct Length
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductWith(Rhs)
    {
        static if (is(Rhs == Length))
            alias ProductWith = Area;
        else
            alias ProductWith = void;
    }

    template QuotientWith(Rhs)
    {
        static if (is(Rhs == Time))
            alias QuotientWith = Velocity;
        else
            alias QuotientWith = void;
    }
}

struct Time
{
    alias Dimension = TimeDimension;
    alias CanonicalUnit = Second;
}

struct Area
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

struct Velocity
{
    alias Dimension = VelocityDimension;
    alias CanonicalUnit = MetresPerSecond;

    template QuotientWith(Rhs)
    {
        static if (is(Rhs == Time))
            alias QuotientWith = Acceleration;
        else
            alias QuotientWith = void;
    }
}

struct Acceleration
{
    alias Dimension = AccelerationDimension;
    alias CanonicalUnit = MetresPerSecondSquared;
}

// Consumer-defined result: same Area dimension, different canonical scale.
struct ConsumerAreaKm2
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareKilometre;

    // This reverse hook is intentionally on the consumer-owned type.
    template ProductFromLeft(Lhs)
    {
        static if (is(Lhs == ConsumerLength))
            alias ProductFromLeft = ConsumerAreaKm2;
        else
            alias ProductFromLeft = void;
    }
}

struct ConsumerLength
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    // Consumer owns both this Spec and the semantic choice of km^2 result.
    template ProductWith(Rhs)
    {
        static if (is(Rhs == ConsumerLength))
            alias ProductWith = ConsumerAreaKm2;
        else
            alias ProductWith = void;
    }
}

// A separate consumer-owned RHS demonstrates the reverse extension hook.
struct ExistingLikeLength
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}

struct ConsumerRhs
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;

    template ProductFromLeft(Lhs)
    {
        static if (is(Lhs == ExistingLikeLength))
            alias ProductFromLeft = ConsumerAreaKm2;
        else
            alias ProductFromLeft = void;
    }
}

// --- Open semantic dispatch ------------------------------------------------

template MulResult(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "ProductWith"))
        alias Candidate = Lhs.ProductWith!Rhs;
    else
        alias Candidate = void;

    static if (!is(Candidate == void))
        alias MulResult = Candidate;
    else static if (__traits(hasMember, Rhs, "ProductFromLeft"))
        alias MulResult = Rhs.ProductFromLeft!Lhs;
    else
        alias MulResult = void;
}

template DivResult(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "QuotientWith"))
        alias DivResult = Lhs.QuotientWith!Rhs;
    else
        alias DivResult = void;
}

// --- Result validation -----------------------------------------------------

template ProductModel(Lhs, Rhs)
{
    alias ResultSpec = MulResult!(Lhs, Rhs);
    static assert(!is(ResultSpec == void));

    alias ResultDimension =
        MulDimension!(Lhs.Dimension, Rhs.Dimension);
    alias MathematicalUnit =
        MulUnit!(Lhs.CanonicalUnit, Rhs.CanonicalUnit);

    static assert(is(ResultSpec.Dimension == ResultDimension));
    static assert(is(MathematicalUnit.DimensionType == ResultDimension));
    static assert(is(ResultSpec.CanonicalUnit.DimensionType == ResultDimension));

    alias Rescale = DivRatio!(
        MathematicalUnit.ScaleType,
        ResultSpec.CanonicalUnit.ScaleType);
}

template QuotientModel(Lhs, Rhs)
{
    alias ResultSpec = DivResult!(Lhs, Rhs);
    static assert(!is(ResultSpec == void));

    alias ResultDimension =
        DivDimension!(Lhs.Dimension, Rhs.Dimension);
    alias MathematicalUnit =
        DivUnit!(Lhs.CanonicalUnit, Rhs.CanonicalUnit);

    static assert(is(ResultSpec.Dimension == ResultDimension));
    static assert(is(MathematicalUnit.DimensionType == ResultDimension));
    static assert(is(ResultSpec.CanonicalUnit.DimensionType == ResultDimension));

    alias Rescale = DivRatio!(
        MathematicalUnit.ScaleType,
        ResultSpec.CanonicalUnit.ScaleType);
}

// --- Compile-time probes ---------------------------------------------------

static assert(is(MulDimension!(LengthDimension, LengthDimension)
    == AreaDimension));
static assert(is(DivDimension!(LengthDimension, TimeDimension)
    == VelocityDimension));
static assert(is(DivDimension!(VelocityDimension, TimeDimension)
    == AccelerationDimension));

static assert(SquareMillimetre.ScaleType.numerator == 1);
static assert(SquareMillimetre.ScaleType.denominator == 1_000_000);
static assert(SquareKilometre.ScaleType.numerator == 1_000_000);
static assert(SquareKilometre.ScaleType.denominator == 1);

static assert(KilometresPerHour.ScaleType.numerator == 1000);
static assert(KilometresPerHour.ScaleType.denominator == 3600);
// This minimal Ratio intentionally does not reduce: 1000/3600 is the
// unreduced exact representation of 5/18. Production ExactRatio would reduce.

alias AreaModel = ProductModel!(Length, Length);
static assert(is(AreaModel.ResultSpec == Area));
static assert(AreaModel.Rescale.numerator == 1);
static assert(AreaModel.Rescale.denominator == 1);

alias VelocityModel = QuotientModel!(Length, Time);
static assert(is(VelocityModel.ResultSpec == Velocity));
static assert(VelocityModel.Rescale.numerator == 1);
static assert(VelocityModel.Rescale.denominator == 1);

alias AccelerationModel = QuotientModel!(Velocity, Time);
static assert(is(AccelerationModel.ResultSpec == Acceleration));
static assert(AccelerationModel.Rescale.numerator == 1);
static assert(AccelerationModel.Rescale.denominator == 1);

alias ConsumerKm2Model = ProductModel!(ConsumerLength, ConsumerLength);
static assert(is(ConsumerKm2Model.ResultSpec == ConsumerAreaKm2));
// m^2 -> km^2 requires multiplication by 1 / 1_000_000.
static assert(ConsumerKm2Model.Rescale.numerator == 1);
static assert(ConsumerKm2Model.Rescale.denominator == 1_000_000);

alias ReverseHookModel = ProductModel!(ExistingLikeLength, ConsumerRhs);
static assert(is(ReverseHookModel.ResultSpec == ConsumerAreaKm2));
static assert(ReverseHookModel.Rescale.numerator == 1);
static assert(ReverseHookModel.Rescale.denominator == 1_000_000);

struct NoRelation
{
    alias Dimension = LengthDimension;
    alias CanonicalUnit = Metre;
}
static assert(is(MulResult!(NoRelation, NoRelation) == void));
