module r04_11_integral_rescale_probe;

import r04_11_probe;
import r04_11_third_customization_probe;

// Research-only classification for a direct integral product.
//
// A direct integral operator may only exist when canonical rescaling is exact
// for every mathematically possible integral product. For a rational rescale
// N/D in lowest terms, that requires D == 1. A fractional rescale can be exact
// for selected values, but not for every integral input pair.

template gcd(long A, long B)
{
    enum long a = A < 0 ? -A : A;
    enum long b = B < 0 ? -B : B;
    static if (b == 0)
        enum gcd = a;
    else
        enum gcd = gcd!(b, a % b);
}

template ReducedRatio(long N, long D)
{
    static assert(D != 0);
    enum long sign = D < 0 ? -1 : 1;
    enum long divisor = gcd!(N, D);
    enum long numerator = sign * N / divisor;
    enum long denominator = sign * D / divisor;
}

template IsTotalIntegralRescale(R)
{
    alias Reduced = ReducedRatio!(R.numerator, R.denominator);
    enum IsTotalIntegralRescale = Reduced.denominator == 1;
}

// Standard canonical products deliberately line up:
// m * m -> m², so no post-product scale conversion is needed.
alias StandardAreaModel = ProductModel!(Length, Length);
static assert(StandardAreaModel.Rescale.numerator == 1);
static assert(StandardAreaModel.Rescale.denominator == 1);
static assert(IsTotalIntegralRescale!(StandardAreaModel.Rescale));

// ConsumerAreaKm2 has canonical km² while both input Specs use canonical m.
// Mathematical product is therefore m² and storage wants km².
alias Km2Model = ProductModel!(ConsumerLength, ConsumerLength);
static assert(Km2Model.Rescale.numerator == 1);
static assert(Km2Model.Rescale.denominator == 1_000_000);
static assert(!IsTotalIntegralRescale!(Km2Model.Rescale));

// The distinction is value-dependent exactness versus operator-total exactness:
// 1_000_000 m² converts exactly to 1 km², but 1 m² cannot be represented by an
// integral km² Rep.
enum long exactlyConvertibleSquareMetres = 1_000_000;
enum long nonConvertibleSquareMetres = 1;

static assert(
    (exactlyConvertibleSquareMetres * Km2Model.Rescale.numerator)
        % Km2Model.Rescale.denominator == 0);
static assert(
    (nonConvertibleSquareMetres * Km2Model.Rescale.numerator)
        % Km2Model.Rescale.denominator != 0);

// A scale with an integer multiplier is total with respect to exactness, though
// overflow still needs the independent ResultRep/range proof.
alias IntegerScale = ReducedRatio!(1_000_000, 1);
static assert(IsTotalIntegralRescale!IntegerScale);

// Reduction matters: 2/2 is semantically scale 1.
alias ReducibleIdentity = ReducedRatio!(2, 2);
static assert(IsTotalIntegralRescale!ReducibleIdentity);
