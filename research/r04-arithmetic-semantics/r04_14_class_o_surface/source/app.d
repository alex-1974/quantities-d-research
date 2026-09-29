module app;

import std.meta : AliasSeq;
import std.traits : isIntegral, isSigned;

alias Reps = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);

private enum bits(T) = T.sizeof * 8;
private enum posBits(T) = bits!T - (isSigned!T ? 1 : 0);
private enum negPow(T) = isSigned!T ? bits!T - 1 : 0;

private struct Shape
{
    size_t minPow;
    size_t maxBits;
}

private enum sumMaxBits(size_t a, size_t b) =
    (a > b ? a : b) + 1;
private enum productMaxBits(size_t a, size_t b) = a + b;

private template AddShape(A, B)
{
    static if (isSigned!A && isSigned!B)
        enum AddShape = Shape(
            negPow!A == negPow!B
                ? negPow!A + 1
                : (negPow!A > negPow!B ? negPow!A + 1 : negPow!B + 1),
            sumMaxBits!(posBits!A, posBits!B));
    else static if (!isSigned!A && !isSigned!B)
        enum AddShape = Shape(0, sumMaxBits!(posBits!A, posBits!B));
    else static if (isSigned!A)
        enum AddShape = Shape(negPow!A, sumMaxBits!(posBits!A, posBits!B));
    else
        enum AddShape = Shape(negPow!B, sumMaxBits!(posBits!A, posBits!B));
}

private template SubShape(A, B)
{
    static if (isSigned!A && isSigned!B)
        enum SubShape = Shape(
            negPow!A >= posBits!B ? negPow!A + 1 : posBits!B + 1,
            posBits!A >= negPow!B ? posBits!A + 1 : negPow!B + 1);
    else static if (!isSigned!A && !isSigned!B)
        enum SubShape = Shape(posBits!B, posBits!A);
    else static if (isSigned!A)
        enum SubShape = Shape(
            negPow!A >= posBits!B ? negPow!A + 1 : posBits!B + 1,
            posBits!A);
    else
        enum SubShape = Shape(
            posBits!B,
            posBits!A >= negPow!B ? posBits!A + 1 : negPow!B + 1);
}

private template MulShape(A, B)
{
    static if (!isSigned!A && !isSigned!B)
        enum MulShape = Shape(0, productMaxBits!(posBits!A, posBits!B));
    else static if (isSigned!A && isSigned!B)
        enum MulShape = Shape(
            negPow!A + posBits!B,
            negPow!A + negPow!B + 1);
    else static if (isSigned!A)
        enum MulShape = Shape(
            negPow!A + posBits!B,
            posBits!A + posBits!B);
    else
        enum MulShape = Shape(
            posBits!A + negPow!B,
            posBits!A + posBits!B);
}

private template FitsShape(T, alias S)
{
    static if (isSigned!T)
        enum FitsShape =
            S.minPow <= bits!T - 1 &&
            S.maxBits <= bits!T - 1;
    else
        enum FitsShape = S.minPow == 0 && S.maxBits <= bits!T;
}

private template SelectRep(alias S)
{
    static if (FitsShape!(byte, S)) alias SelectRep = byte;
    else static if (FitsShape!(ubyte, S)) alias SelectRep = ubyte;
    else static if (FitsShape!(short, S)) alias SelectRep = short;
    else static if (FitsShape!(ushort, S)) alias SelectRep = ushort;
    else static if (FitsShape!(int, S)) alias SelectRep = int;
    else static if (FitsShape!(uint, S)) alias SelectRep = uint;
    else static if (FitsShape!(long, S)) alias SelectRep = long;
    else static if (FitsShape!(ulong, S)) alias SelectRep = ulong;
    else alias SelectRep = void;
}

template AddRep(A, B)
{
    alias AddRep = SelectRep!(AddShape!(A, B));
}

template SubRep(A, B)
{
    alias SubRep = SelectRep!(SubShape!(A, B));
}

template MulRep(A, B)
{
    alias MulRep = SelectRep!(MulShape!(A, B));
}

enum isClassOAdd(A, B) = is(AddRep!(A, B) == void);
enum isClassOSub(A, B) = is(SubRep!(A, B) == void);
enum isClassOMul(A, B) = is(MulRep!(A, B) == void);

template CountClassO(alias Predicate, Ts...)
{
    static if (Ts.length == 0)
        enum CountClassO = 0;
    else
    {
        alias A = Ts[0];
        enum row = countRow!(Predicate, A, Reps);
        enum CountClassO = row + CountClassO!(Predicate, Ts[1 .. $]);
    }
}

template countRow(alias Predicate, A, Ts...)
{
    static if (Ts.length == 0)
        enum countRow = 0;
    else
        enum countRow =
            (Predicate!(A, Ts[0]) ? 1 : 0) +
            countRow!(Predicate, A, Ts[1 .. $]);
}

enum addClassOCount = CountClassO!(isClassOAdd, Reps);
enum subClassOCount = CountClassO!(isClassOSub, Reps);
enum mulClassOCount = CountClassO!(isClassOMul, Reps);

// Representative boundaries. These assertions intentionally use the exact
// production Class-W shape algorithm rather than D's native arithmetic types.
static assert(!isClassOAdd!(int, int));
static assert(is(AddRep!(int, int) == long));
// Do not prescribe AddRep!(uint, uint) here. Probe 1 observes the current
// production algorithm; any surprising classification is evidence to audit.
static assert(!isClassOAdd!(uint, uint));
static assert(isClassOAdd!(long, long));
static assert(isClassOAdd!(ulong, ulong));

static assert(!isClassOSub!(uint, uint));
static assert(is(SubRep!(uint, uint) == long));
static assert(isClassOSub!(long, long));
static assert(isClassOSub!(ulong, ulong));

static assert(!isClassOMul!(int, int));
static assert(is(MulRep!(int, int) == long));
static assert(!isClassOMul!(uint, uint));
static assert(is(MulRep!(uint, uint) == ulong));
static assert(isClassOMul!(long, long));
static assert(isClassOMul!(ulong, ulong));

// Symmetry is required for addition and multiplication classification.
static foreach (A; Reps)
{
    static foreach (B; Reps)
    {
        static assert(isClassOAdd!(A, B) == isClassOAdd!(B, A));
        static assert(isClassOMul!(A, B) == isClassOMul!(B, A));
    }
}

// Probe output is deliberately compact and deterministic. It gives the three
// Class-O totals and then one 8x8 bitmap per operation in Reps order.
void printMatrix(alias Predicate)(string label)
{
    import std.stdio : write, writeln;

    writeln(label);
    static foreach (A; Reps)
    {
        static foreach (B; Reps)
            write(Predicate!(A, B) ? 'O' : 'W');
        writeln();
    }
}

void main()
{
    import std.stdio : writeln;

    writeln("Rep order: byte ubyte short ushort int uint long ulong");
    writeln("Class-O counts: add=", addClassOCount,
        " sub=", subClassOCount, " mul=", mulClassOCount);
    printMatrix!isClassOAdd("ADD");
    printMatrix!isClassOSub("SUB");
    printMatrix!isClassOMul("MUL");
}
