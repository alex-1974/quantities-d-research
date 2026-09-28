module r04_11_quantity_product_integration_probe;

// R04.11 production-shaped end-to-end Quantity product probe.
// It deliberately keeps the model focused on the two reference paths:
//   direct total integral product
//   value-dependent exact integral product after canonical rescaling.

import std.traits : isIntegral;

// ---------- exact scale ----------

struct Ratio(long N, long D)
{
    static assert(D > 0);
    enum numerator = N;
    enum denominator = D;
}

template DivRatio(A, B)
{
    static assert(B.numerator != 0);
    enum n = A.numerator * B.denominator;
    enum d = A.denominator * B.numerator;
    static if (n == 0)
        alias DivRatio = Ratio!(0, 1);
    else
    {
        enum an = n < 0 ? -n : n;
        enum ad = d < 0 ? -d : d;
        enum g = gcd(an, ad);
        enum rn = d < 0 ? -(n / g) : n / g;
        enum rd = ad / g;
        alias DivRatio = Ratio!(rn, rd);
    }
}

private long gcd(long a, long b)
{
    while (b != 0)
    {
        auto r = a % b;
        a = b;
        b = r;
    }
    return a == 0 ? 1 : a;
}

// ---------- dimensions / units ----------
// The full open canonical dimension machinery is proven separately.
// This integration probe uses its resulting type-identity contract.

struct LengthDimension {}
struct AreaDimension {}

struct Unit(DimensionT, ScaleT)
{
    alias Dimension = DimensionT;
    alias Scale = ScaleT;
}

alias Metre = Unit!(LengthDimension, Ratio!(1, 1));
alias SquareMetre = Unit!(AreaDimension, Ratio!(1, 1));
alias SquareKilometre = Unit!(AreaDimension, Ratio!(1_000_000, 1));

// ---------- semantic Specs ----------

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
}

struct Area
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareMetre;
}

// Consumer-style alternate semantic result with same mathematical dimension
// but a different canonical storage unit.
struct AreaKm2
{
    alias Dimension = AreaDimension;
    alias CanonicalUnit = SquareKilometre;
}

template ProductResultSpec(Lhs, Rhs)
{
    static if (__traits(hasMember, Lhs, "ProductWith"))
        alias ProductResultSpec = Lhs.ProductWith!Rhs;
    else
        alias ProductResultSpec = void;
}

// Explicit relation context models the already-proven orphan-relation escape
// hatch and lets the same operand Specs select a consumer ResultSpec.
struct Km2Relations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == Length) && is(Rhs == Length))
            alias Product = AreaKm2;
        else
            alias Product = void;
    }
}

// ---------- Rep range policy ----------
// Focused production-shaped reference: int * int is widened before multiply.

template ProductRep(A, B)
{
    static if (is(A == int) && is(B == int))
        alias ProductRep = long;
    else
        alias ProductRep = void;
}

// ---------- Quantity ----------

struct Quantity(Spec, Rep)
{
    Rep canonical;

    package static Quantity fromCanonical(Rep value)
        @safe pure nothrow @nogc
    {
        return Quantity(value);
    }
}

// ---------- result-unit / rescale ----------

template MathematicalProductUnit(LhsSpec, RhsSpec)
{
    // For the reference Length x Length path:
    static assert(is(LhsSpec.Dimension == LengthDimension));
    static assert(is(RhsSpec.Dimension == LengthDimension));
    alias MathematicalProductUnit = SquareMetre;
}

template CanonicalRescale(LhsSpec, RhsSpec, ResultSpec)
{
    alias MathUnit = MathematicalProductUnit!(LhsSpec, RhsSpec);
    static assert(is(MathUnit.Dimension == ResultSpec.Dimension));
    static assert(is(ResultSpec.CanonicalUnit.Dimension == ResultSpec.Dimension));
    alias CanonicalRescale =
        DivRatio!(MathUnit.Scale, ResultSpec.CanonicalUnit.Scale);
}

template DirectIntegralProductAllowed(LhsSpec, LhsRep, RhsSpec, RhsRep, ResultSpec)
{
    alias Rep = ProductRep!(LhsRep, RhsRep);
    static if (is(Rep == void))
        enum DirectIntegralProductAllowed = false;
    else
    {
        alias Scale = CanonicalRescale!(LhsSpec, RhsSpec, ResultSpec);
        // The full scaled-range oracle is proven separately. For this
        // integration reference, denominator==1 establishes total exactness;
        // Scale=1 is the direct standard-catalogue path.
        enum DirectIntegralProductAllowed =
            isIntegral!LhsRep &&
            isIntegral!RhsRep &&
            Scale.denominator == 1 &&
            Scale.numerator == 1;
    }
}

// ---------- direct product ----------

auto directMul(LhsSpec, LhsRep, RhsSpec, RhsRep)(
    Quantity!(LhsSpec, LhsRep) lhs,
    Quantity!(RhsSpec, RhsRep) rhs)
    @safe pure nothrow @nogc
    if (!is(ProductResultSpec!(LhsSpec, RhsSpec) == void) &&
        DirectIntegralProductAllowed!(
            LhsSpec, LhsRep, RhsSpec, RhsRep,
            ProductResultSpec!(LhsSpec, RhsSpec)))
{
    alias ResultSpec = ProductResultSpec!(LhsSpec, RhsSpec);
    alias ResultRep = ProductRep!(LhsRep, RhsRep);
    return Quantity!(ResultSpec, ResultRep).fromCanonical(
        cast(ResultRep) lhs.canonical * cast(ResultRep) rhs.canonical);
}

// ---------- exact product ----------

enum ProductFailure : ubyte
{
    inexact,
    overflow
}

struct ExactArithmeticResult(T, Failure)
{
private:
    T payload_;
    Failure failure_;
    bool hasValue_;

public:
    @property bool hasValue() const @safe pure nothrow @nogc
    {
        return hasValue_;
    }

    bool tryValue(out T value) const @safe pure nothrow @nogc
    {
        if (!hasValue_)
            return false;
        value = payload_;
        return true;
    }

    bool tryFailure(out Failure failure) const @safe pure nothrow @nogc
    {
        if (hasValue_)
            return false;
        failure = failure_;
        return true;
    }

package:
    static ExactArithmeticResult exact(T value)
        @safe pure nothrow @nogc
    {
        ExactArithmeticResult result;
        result.payload_ = value;
        result.hasValue_ = true;
        return result;
    }

    static ExactArithmeticResult failed(Failure failure)
        @safe pure nothrow @nogc
    {
        ExactArithmeticResult result;
        result.failure_ = failure;
        return result;
    }
}

template ProductResult(T)
{
    alias ProductResult = ExactArithmeticResult!(T, ProductFailure);
}

auto exactMul(Relations, LhsSpec, LhsRep, RhsSpec, RhsRep)(
    Relations relations,
    Quantity!(LhsSpec, LhsRep) lhs,
    Quantity!(RhsSpec, RhsRep) rhs)
    @safe pure nothrow @nogc
    if (!is(Relations.Product!(LhsSpec, RhsSpec) == void) &&
        !is(ProductRep!(LhsRep, RhsRep) == void))
{
    alias ResultSpec = Relations.Product!(LhsSpec, RhsSpec);
    alias ResultRep = ProductRep!(LhsRep, RhsRep);
    alias ResultQuantity = Quantity!(ResultSpec, ResultRep);
    alias Result = ProductResult!ResultQuantity;
    alias Scale = CanonicalRescale!(LhsSpec, RhsSpec, ResultSpec);

    static assert(Scale.numerator > 0);
    static assert(Scale.denominator > 0);

    const raw = cast(ResultRep) lhs.canonical *
                cast(ResultRep) rhs.canonical;

    // Reference fractional-rescale path. Multiplication overflow is impossible
    // for int x int -> long; numerator is 1 in this probe.
    static if (Scale.numerator == 1)
    {
        if (raw % Scale.denominator != 0)
            return Result.failed(ProductFailure.inexact);

        return Result.exact(ResultQuantity.fromCanonical(
            raw / Scale.denominator));
    }
    else
    {
        // A general integer multiplier requires the already-researched
        // post-rescale range gate before this path can be promoted.
        return Result.failed(ProductFailure.overflow);
    }
}

unittest
{
    alias QLength = Quantity!(Length, int);

    auto a = QLength.fromCanonical(3);
    auto b = QLength.fromCanonical(4);

    auto area = directMul(a, b);
    static assert(is(typeof(area) == Quantity!(Area, long)));
    assert(area.canonical == 12);

    Km2Relations relations;

    auto inexact = exactMul(relations, a, b);
    static assert(is(typeof(inexact) ==
        ProductResult!(Quantity!(AreaKm2, long))));
    assert(!inexact.hasValue);

    ProductFailure failure;
    assert(inexact.tryFailure(failure));
    assert(failure == ProductFailure.inexact);

    auto kmA = QLength.fromCanonical(1000);
    auto kmB = QLength.fromCanonical(1000);
    auto exact = exactMul(relations, kmA, kmB);

    Quantity!(AreaKm2, long) km2;
    assert(exact.tryValue(km2));
    assert(km2.canonical == 1);
}

void main() {}
