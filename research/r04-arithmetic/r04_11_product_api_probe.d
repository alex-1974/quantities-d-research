module r04_11_product_api_probe;

// R04.11 public-API shape probe.
// This intentionally models API semantics, not production implementation.

enum ProductStatus : ubyte
{
    exact,
    inexact,
    overflow
}

struct ProductResult(T)
{
private:
    T payload_;
    bool hasValue_;
    ProductStatus status_ = ProductStatus.inexact;

public:
    @property bool hasValue() const @safe pure nothrow @nogc
    {
        return hasValue_;
    }

    @property ProductStatus status() const @safe pure nothrow @nogc
    {
        return status_;
    }

    bool tryValue(out T value) const @safe pure nothrow @nogc
    {
        if (!hasValue_)
            return false;
        value = payload_;
        return true;
    }

package:
    static ProductResult exact(T value) @safe pure nothrow @nogc
    {
        ProductResult result;
        result.payload_ = value;
        result.hasValue_ = true;
        result.status_ = ProductStatus.exact;
        return result;
    }

    static ProductResult inexact() @safe pure nothrow @nogc
    {
        ProductResult result;
        result.status_ = ProductStatus.inexact;
        return result;
    }

    static ProductResult overflow() @safe pure nothrow @nogc
    {
        ProductResult result;
        result.status_ = ProductStatus.overflow;
        return result;
    }
}

struct AreaMetre { long value; }
struct AreaKilometre { long value; }

// Model the total direct operator case: canonical rescale = 1 and the chosen
// ResultRep contains the complete product range.
AreaMetre safeDirectProduct(int lhs, int rhs)
    @safe pure nothrow @nogc
{
    return AreaMetre(cast(long) lhs * cast(long) rhs);
}

// Model the value-dependent exact case: mathematical product is m2, result
// canonical storage is km2, so canonical rescale = 1/1_000_000.
ProductResult!AreaKilometre exactMul(int lhs, int rhs)
    @safe pure nothrow @nogc
{
    const product = cast(long) lhs * cast(long) rhs;
    enum denominator = 1_000_000L;

    if (product % denominator != 0)
        return ProductResult!AreaKilometre.inexact();

    return ProductResult!AreaKilometre.exact(
        AreaKilometre(product / denominator));
}

// Probe the semantic distinction between exactMul and a hypothetical
// checkedMul. For integral derived products under the current contract,
// successful payload production is exact; inexact has no payload, and range
// overflow has no payload. Therefore checkedMul would currently expose the
// same state machine unless a future policy gives it additional semantics.
alias ExactMulResult = ProductResult!AreaKilometre;
alias CheckedMulResult = ProductResult!AreaKilometre;
static assert(is(ExactMulResult == CheckedMulResult));

static assert(ProductResult!AreaKilometre.init.status ==
    ProductStatus.inexact);
static assert(!ProductResult!AreaKilometre.init.hasValue);

unittest
{
    auto direct = safeDirectProduct(3, 4);
    assert(direct.value == 12);

    auto inexact = exactMul(3, 4);
    assert(inexact.status == ProductStatus.inexact);
    assert(!inexact.hasValue);

    AreaKilometre value;
    assert(!inexact.tryValue(value));

    auto exact = exactMul(1000, 1000);
    assert(exact.status == ProductStatus.exact);
    assert(exact.hasValue);
    assert(exact.tryValue(value));
    assert(value.value == 1);
}

// Naming/API conclusion tested by this probe:
//
//     a * b
//         only when the operation is total for every representable operand.
//
//     a.exactMul(b)
//         explicit value-dependent exact operation when the direct operator is
//         unavailable due to canonical rescale exactness and/or range policy.
//
// A separate checkedMul is not justified by this integral product state model
// unless later research establishes distinct checked semantics.


void main() {}
