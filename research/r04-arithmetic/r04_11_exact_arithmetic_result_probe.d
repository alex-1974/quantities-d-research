module r04_11_exact_arithmetic_result_probe;

// R04.11 result-type factoring probe.
// Goal: share the constructive payload mechanism without collapsing
// operation-specific status semantics.

enum ProductFailure : ubyte
{
    inexact,
    overflow
}

enum DivisionFailure : ubyte
{
    inexact,
    divisionByZero
}

struct ExactArithmeticResult(T, Failure)
    if (is(Failure == enum))
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

struct AreaKilometre
{
    long value;
}

struct Quotient
{
    long value;
}

alias ProductResult = ExactArithmeticResult!(
    AreaKilometre, ProductFailure);
alias DivisionResult = ExactArithmeticResult!(
    Quotient, DivisionFailure);

// Operation-specific failure domains remain distinct types.
static assert(!is(ProductFailure == DivisionFailure));
static assert(!is(ProductResult == DivisionResult));

unittest
{
    auto pExact = ProductResult.exact(AreaKilometre(1));
    assert(pExact.hasValue);

    AreaKilometre area;
    assert(pExact.tryValue(area));
    assert(area.value == 1);

    ProductFailure pf;
    assert(!pExact.tryFailure(pf));

    auto pInexact = ProductResult.failed(ProductFailure.inexact);
    assert(!pInexact.hasValue);
    assert(pInexact.tryFailure(pf));
    assert(pf == ProductFailure.inexact);

    auto pOverflow = ProductResult.failed(ProductFailure.overflow);
    assert(pOverflow.tryFailure(pf));
    assert(pf == ProductFailure.overflow);

    auto dZero = DivisionResult.failed(DivisionFailure.divisionByZero);
    DivisionFailure df;
    assert(dZero.tryFailure(df));
    assert(df == DivisionFailure.divisionByZero);
}

// Design conclusion:
//
// - sharing the constructive success/failure carrier is viable;
// - failure/status enums remain operation-specific;
// - no broad ArithmeticStatus is required;
// - public aliases can remain ProductResult!T / DivisionResult!T if desired,
//   while implementation reuses one internal carrier.
//
// This preserves semantic precision while eliminating duplicated state logic.

void main() {}
