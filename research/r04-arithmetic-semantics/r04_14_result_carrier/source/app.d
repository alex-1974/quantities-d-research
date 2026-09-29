module app;

enum CheckedFailure : ubyte { overflow }

enum CheckedProductStatus : ubyte
{
    exact,
    inexact,
    overflow
}

private struct ValueOrFailure(T, Failure)
    if (is(Failure == enum))
{
private:
    T value_;
    Failure failure_ = Failure.init;
    bool hasValue_;

public:
    @property bool hasValue() const @safe pure nothrow @nogc
    {
        return hasValue_;
    }

    static ValueOrFailure value(T v) @safe pure nothrow @nogc
    {
        ValueOrFailure r;
        r.value_ = v;
        r.hasValue_ = true;
        return r;
    }

    static ValueOrFailure failed(Failure f) @safe pure nothrow @nogc
    {
        ValueOrFailure r;
        r.failure_ = f;
        return r;
    }

    bool tryValue(out T v) const @safe pure nothrow @nogc
    {
        if (!hasValue_) return false;
        v = value_;
        return true;
    }

    bool tryFailure(out Failure f) const @safe pure nothrow @nogc
    {
        if (hasValue_) return false;
        f = failure_;
        return true;
    }
}

alias CheckedResult(T) = ValueOrFailure!(T, CheckedFailure);

struct CheckedProductResult(T)
{
private:
    T value_;
    CheckedProductStatus status_ = CheckedProductStatus.inexact;

public:
    @property CheckedProductStatus status() const @safe pure nothrow @nogc
    {
        return status_;
    }

    @property bool hasValue() const @safe pure nothrow @nogc
    {
        return status_ == CheckedProductStatus.exact;
    }

    static CheckedProductResult exact(T v) @safe pure nothrow @nogc
    {
        CheckedProductResult r;
        r.value_ = v;
        r.status_ = CheckedProductStatus.exact;
        return r;
    }

    static CheckedProductResult inexact() @safe pure nothrow @nogc
    {
        CheckedProductResult r;
        r.status_ = CheckedProductStatus.inexact;
        return r;
    }

    static CheckedProductResult overflow() @safe pure nothrow @nogc
    {
        CheckedProductResult r;
        r.status_ = CheckedProductStatus.overflow;
        return r;
    }

    bool tryValue(out T v) const @safe pure nothrow @nogc
    {
        if (!hasValue) return false;
        v = value_;
        return true;
    }
}

@safe pure nothrow @nogc
bool ctfeProbe()
{
    auto checked = CheckedResult!long.value(42);
    long x;
    if (!checked.tryValue(x) || x != 42) return false;

    auto overflow = CheckedResult!long.failed(CheckedFailure.overflow);
    CheckedFailure f;
    if (overflow.tryValue(x)) return false;
    if (!overflow.tryFailure(f) || f != CheckedFailure.overflow) return false;

    auto exact = CheckedProductResult!long.exact(7);
    if (exact.status != CheckedProductStatus.exact) return false;
    if (!exact.tryValue(x) || x != 7) return false;

    auto inexact = CheckedProductResult!long.inexact();
    if (inexact.status != CheckedProductStatus.inexact || inexact.hasValue)
        return false;

    auto productOverflow = CheckedProductResult!long.overflow();
    if (productOverflow.status != CheckedProductStatus.overflow ||
        productOverflow.hasValue)
        return false;

    return true;
}

static assert(ctfeProbe());

// Default state must be failure, never a fabricated value.
enum defaultChecked = CheckedResult!long.init;
static assert(!defaultChecked.hasValue);

enum defaultProduct = CheckedProductResult!long.init;
static assert(defaultProduct.status == CheckedProductStatus.inexact);
static assert(!defaultProduct.hasValue);

// The binary checked carrier cannot express inexact/divisionByZero.
static assert(__traits(allMembers, CheckedFailure).length == 1);

// The checked-product carrier cannot express divisionByZero.
static assert(__traits(allMembers, CheckedProductStatus).length == 3);

void main()
{
    import std.stdio : writeln;
    assert(ctfeProbe());
    writeln("R04.14 Probe 9 PASS");
    writeln("checked: value | overflow");
    writeln("checked product: exact | inexact | overflow");
}
