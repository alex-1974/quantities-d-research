module r04_13_quotient_unit_rescale_probe;

// R04.13 probe 3: exact quotient Unit algebra and canonical-storage rescale.
// Minimal local types reproduce the promoted exact-ratio/unit semantics needed
// for this isolated research probe.

struct Ratio(long N, long D)
{
    static assert(D != 0);
    enum numerator = N;
    enum denominator = D;
}

struct Unit(DimensionT, ScaleT)
{
    alias Dimension = DimensionT;
    alias Scale = ScaleT;
}

struct LengthDimension {}
struct TimeDimension {}
struct Dimensionless {}
struct VelocityDimension {}
struct ReciprocalLengthDimension {}

alias Metre = Unit!(LengthDimension, Ratio!(1, 1));
alias Kilometre = Unit!(LengthDimension, Ratio!(1000, 1));
alias Second = Unit!(TimeDimension, Ratio!(1, 1));
alias Hour = Unit!(TimeDimension, Ratio!(3600, 1));

alias One = Unit!(Dimensionless, Ratio!(1, 1));
alias MetresPerSecond = Unit!(VelocityDimension, Ratio!(1, 1));
alias KilometresPerHour = Unit!(VelocityDimension, Ratio!(5, 18));
alias PerMetre = Unit!(ReciprocalLengthDimension, Ratio!(1, 1));
alias PerKilometre = Unit!(ReciprocalLengthDimension, Ratio!(1, 1000));

private long gcd(long a, long b)
{
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0)
    {
        auto r = a % b;
        a = b;
        b = r;
    }
    return a;
}

template Normalize(long N, long D)
{
    static assert(D != 0);
    enum g = gcd(N, D);
    enum nn = N / g;
    enum dd = D / g;
    static if (dd < 0)
        alias Normalize = Ratio!(-nn, -dd);
    else
        alias Normalize = Ratio!(nn, dd);
}

template DivideRatio(A, B)
{
    static assert(B.numerator != 0);
    alias DivideRatio = Normalize!(
        A.numerator * B.denominator,
        A.denominator * B.numerator);
}

template QuotientUnit(A, B, ResultDimension)
{
    alias Scale = DivideRatio!(A.Scale, B.Scale);
    alias QuotientUnit = Unit!(ResultDimension, Scale);
}

// Convert the mathematical quotient unit into ResultSpec.CanonicalUnit.
// scale = MathematicalUnit.Scale / CanonicalUnit.Scale
template CanonicalRescale(MathematicalUnit, CanonicalUnit)
{
    alias CanonicalRescale =
        DivideRatio!(MathematicalUnit.Scale, CanonicalUnit.Scale);
}

struct RatioSpec { alias CanonicalUnit = One; }
struct VelocityMpsSpec { alias CanonicalUnit = MetresPerSecond; }
struct VelocityKphSpec { alias CanonicalUnit = KilometresPerHour; }
struct ReciprocalMetreSpec { alias CanonicalUnit = PerMetre; }
struct ReciprocalKilometreSpec { alias CanonicalUnit = PerKilometre; }

// Same physical units cancel exactly.
alias MetrePerMetre =
    QuotientUnit!(Metre, Metre, Dimensionless);
alias MMToRatio =
    CanonicalRescale!(MetrePerMetre, RatioSpec.CanonicalUnit);
static assert(MMToRatio.numerator == 1);
static assert(MMToRatio.denominator == 1);

// Mixed length units produce a dimensionless scale.
// 1 km / 1 m = 1000 in canonical ratio storage.
alias KilometrePerMetre =
    QuotientUnit!(Kilometre, Metre, Dimensionless);
alias KMToRatio =
    CanonicalRescale!(KilometrePerMetre, RatioSpec.CanonicalUnit);
static assert(KMToRatio.numerator == 1000);
static assert(KMToRatio.denominator == 1);

// 1 m / 1 km = 1/1000: integral canonical storage may be inexact.
alias MetrePerKilometre =
    QuotientUnit!(Metre, Kilometre, Dimensionless);
alias MKToRatio =
    CanonicalRescale!(MetrePerKilometre, RatioSpec.CanonicalUnit);
static assert(MKToRatio.numerator == 1);
static assert(MKToRatio.denominator == 1000);

// Length / Time: km/h expressed in canonical m/s is exactly 5/18.
alias KmPerHour =
    QuotientUnit!(Kilometre, Hour, VelocityDimension);
alias KphToMps =
    CanonicalRescale!(KmPerHour, VelocityMpsSpec.CanonicalUnit);
static assert(KphToMps.numerator == 5);
static assert(KphToMps.denominator == 18);

// The same mathematical km/h quotient stored in km/h canonical units is 1.
alias KphToKph =
    CanonicalRescale!(KmPerHour, VelocityKphSpec.CanonicalUnit);
static assert(KphToKph.numerator == 1);
static assert(KphToKph.denominator == 1);

// Length / Area example represented by scale only:
// m / km^2 = 1 / 1_000_000 per metre.
alias SquareKilometre =
    Unit!(LengthDimension, Ratio!(1_000_000, 1));
alias MetrePerSquareKilometre =
    QuotientUnit!(Metre, SquareKilometre, ReciprocalLengthDimension);
alias ReciprocalM =
    CanonicalRescale!(
        MetrePerSquareKilometre,
        ReciprocalMetreSpec.CanonicalUnit);
static assert(ReciprocalM.numerator == 1);
static assert(ReciprocalM.denominator == 1_000_000);

// In per-kilometre canonical storage that same value rescales by 1/1000.
alias ReciprocalKm =
    CanonicalRescale!(
        MetrePerSquareKilometre,
        ReciprocalKilometreSpec.CanonicalUnit);
static assert(ReciprocalKm.numerator == 1);
static assert(ReciprocalKm.denominator == 1000);

void main() {}
