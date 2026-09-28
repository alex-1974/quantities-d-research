module r04_12_explicit_product_api_probe;

// Probe the total-safe counterpart to:
//   lhs.exactMul!Relations(rhs)
//
// D operators cannot carry a consumer relation provider. An explicit named
// product can, while retaining the distinction between total and
// value-dependent exact multiplication.

struct ForeignLength { int value; }
struct ForeignArea { long value; }

struct Relations
{
    template Product(Lhs, Rhs)
    {
        static if (is(Lhs == ForeignLength) && is(Rhs == ForeignLength))
            alias Product = ForeignArea;
        else
            alias Product = void;
    }
}

private template ExternalProduct(alias R, Lhs, Rhs)
{
    alias ExternalProduct = R.Product!(Lhs, Rhs);
}

// Model a total-safe product: int*int widens to long, rescale is identity.
auto product(alias R, Lhs, Rhs)(Lhs lhs, Rhs rhs)
    if (!is(ExternalProduct!(R, Lhs, Rhs) == void))
{
    alias Out = ExternalProduct!(R, Lhs, Rhs);
    return Out(cast(long)lhs.value * cast(long)rhs.value);
}

// Model the named exact operation under the same relation provider.
auto exactMul(alias R, Lhs, Rhs)(Lhs lhs, Rhs rhs)
    if (!is(ExternalProduct!(R, Lhs, Rhs) == void))
{
    alias Out = ExternalProduct!(R, Lhs, Rhs);
    return Out(cast(long)lhs.value * cast(long)rhs.value);
}

enum total = product!Relations(ForeignLength(3), ForeignLength(4));
static assert(is(typeof(total) == ForeignArea));
static assert(total.value == 12);

// UFCS is also possible and reads consistently with exactMul.
enum totalUfcs = ForeignLength(3).product!Relations(ForeignLength(4));
static assert(totalUfcs.value == 12);

enum exact = ForeignLength(3).exactMul!Relations(ForeignLength(4));
static assert(exact.value == 12);

// Intended API distinction:
//
//   a * b
//       total-safe, operand-owned relation
//
//   a.product!Relations(b)
//       total-safe, explicitly consumer-owned relation
//
//   a.exactMul(b)
//       exact/value-dependent, operand-owned relation
//
//   a.exactMul!Relations(b)
//       exact/value-dependent, explicitly consumer-owned relation

void main() {}
