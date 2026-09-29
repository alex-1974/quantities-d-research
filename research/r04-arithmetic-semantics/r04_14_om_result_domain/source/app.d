module app;

import std.bigint : BigInt;
import std.stdio : writeln;

enum Op { add, sub, mul }

struct Range
{
    BigInt lo;
    BigInt hi;
}

BigInt b(T)(T x) { return BigInt(x); }

Range exactRange(A, B)(Op op)
{
    BigInt[2] as = [b(A.min), b(A.max)];
    BigInt[2] bs = [b(B.min), b(B.max)];

    bool first = true;
    Range r;
    foreach (a; as)
    foreach (bb; bs)
    {
        BigInt v;
        final switch (op)
        {
            case Op.add: v = a + bb; break;
            case Op.sub: v = a - bb; break;
            case Op.mul: v = a * bb; break;
        }
        if (first) { r = Range(v, v); first = false; }
        else {
            if (v < r.lo) r.lo = v;
            if (v > r.hi) r.hi = v;
        }
    }
    return r;
}

bool fitsLong(ref Range r)
{
    return r.lo >= b(long.min) && r.hi <= b(long.max);
}

bool fitsUlong(ref Range r)
{
    return r.lo >= b(0) && r.hi <= b(ulong.max);
}

void show(A, B)(string name, Op op)
{
    auto r = exactRange!(A, B)(op);
    writeln(name,
        " | lo=", r.lo,
        " | hi=", r.hi,
        " | long=", fitsLong(r),
        " | ulong=", fitsUlong(r));
}

void main()
{
    writeln("R04.14 Probe 6 — exact OM result domains");

    show!(int, ulong)("int + ulong", Op.add);
    show!(long, ulong)("long + ulong", Op.add);
    show!(ulong, long)("ulong + long", Op.add);

    show!(int, ulong)("int * ulong", Op.mul);
    show!(long, ulong)("long * ulong", Op.mul);
    show!(ulong, long)("ulong * long", Op.mul);

    show!(ulong, ulong)("ulong - ulong", Op.sub);
    show!(int, ulong)("int - ulong", Op.sub);
    show!(ulong, int)("ulong - int", Op.sub);
    show!(long, ulong)("long - ulong", Op.sub);
    show!(ulong, long)("ulong - long", Op.sub);

    // Mathematical witnesses proving that a 64-bit signed/unsigned choice
    // necessarily discards successful values for representative OM cases.
    auto addIU = exactRange!(int, ulong)(Op.add);
    assert(addIU.lo < b(0));
    assert(addIU.hi > b(long.max));
    assert(!fitsLong(addIU) && !fitsUlong(addIU));

    auto subUU = exactRange!(ulong, ulong)(Op.sub);
    assert(subUU.lo < b(long.min));
    assert(subUU.hi > b(long.max));
    assert(!fitsLong(subUU) && !fitsUlong(subUU));

    auto mulIU = exactRange!(int, ulong)(Op.mul);
    assert(mulIU.lo < b(long.min));
    assert(mulIU.hi > b(ulong.max));
    assert(!fitsLong(mulIU) && !fitsUlong(mulIU));

    writeln("R04.14 Probe 6 PASS");
}
