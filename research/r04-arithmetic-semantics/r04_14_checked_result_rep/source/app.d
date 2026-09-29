module app;

import std.meta : AliasSeq;
import std.traits : isIntegral, isSigned;

alias Reps = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);

template CommonOperandRep(A, B)
{
    static assert(isIntegral!A && isIntegral!B);

    static if (isSigned!A || isSigned!B)
    {
        // A signed common Rep must contain every positive unsigned endpoint too.
        static if (A.min >= long.min && B.min >= long.min &&
                   A.max <= long.max && B.max <= long.max)
            alias CommonOperandRep = long;
        else
            alias CommonOperandRep = void;
    }
    else
        alias CommonOperandRep = ulong;
}

enum MixedDomainKind
{
    naturalSigned,
    naturalUnsigned,
    ambiguous
}

template AddCheckedDomain(A, B)
{
    static if (isSigned!A && isSigned!B)
        enum AddCheckedDomain = MixedDomainKind.naturalSigned;
    else static if (!isSigned!A && !isSigned!B)
        enum AddCheckedDomain = MixedDomainKind.naturalUnsigned;
    else
    {
        alias S = typeof(isSigned!A ? A.init : B.init);
        alias U = typeof(isSigned!A ? B.init : A.init);
        static if (U.max <= long.max)
            enum AddCheckedDomain = MixedDomainKind.naturalSigned;
        else
            enum AddCheckedDomain = MixedDomainKind.ambiguous;
    }
}

template MulCheckedDomain(A, B)
{
    alias MulCheckedDomain = AddCheckedDomain!(A, B);
}

template SubCheckedDomain(A, B)
{
    // Subtraction can create negatives even for unsigned operands.
    static if (A.max <= long.max && B.max <= long.max)
        enum SubCheckedDomain = MixedDomainKind.naturalSigned;
    else
        enum SubCheckedDomain = MixedDomainKind.ambiguous;
}

template CandidateRep(alias Domain)
{
    static if (Domain == MixedDomainKind.naturalSigned)
        alias CandidateRep = long;
    else static if (Domain == MixedDomainKind.naturalUnsigned)
        alias CandidateRep = ulong;
    else
        alias CandidateRep = void;
}

// Clear O64 examples.
static assert(is(CandidateRep!(AddCheckedDomain!(long, long)) == long));
static assert(is(CandidateRep!(AddCheckedDomain!(ulong, ulong)) == ulong));
static assert(is(CandidateRep!(AddCheckedDomain!(long, uint)) == long));
static assert(is(CandidateRep!(AddCheckedDomain!(ulong, uint)) == ulong));

static assert(is(CandidateRep!(MulCheckedDomain!(long, long)) == long));
static assert(is(CandidateRep!(MulCheckedDomain!(ulong, ulong)) == ulong));
static assert(is(CandidateRep!(MulCheckedDomain!(long, uint)) == long));
static assert(is(CandidateRep!(MulCheckedDomain!(ulong, uint)) == ulong));

// Mixed full-width signed/unsigned domains are deliberately unresolved.
static assert(is(CandidateRep!(AddCheckedDomain!(long, ulong)) == void));
static assert(is(CandidateRep!(AddCheckedDomain!(ulong, long)) == void));
static assert(is(CandidateRep!(MulCheckedDomain!(long, ulong)) == void));
static assert(is(CandidateRep!(MulCheckedDomain!(ulong, long)) == void));

// Subtraction is stricter: unsigned subtraction may need negative storage.
static assert(is(CandidateRep!(SubCheckedDomain!(uint, uint)) == long));
static assert(is(CandidateRep!(SubCheckedDomain!(long, int)) == long));
static assert(is(CandidateRep!(SubCheckedDomain!(ulong, ulong)) == void));
static assert(is(CandidateRep!(SubCheckedDomain!(long, ulong)) == void));
static assert(is(CandidateRep!(SubCheckedDomain!(ulong, long)) == void));

// Common operand conversion is not a prerequisite for all useful checked pairs.
static assert(is(CommonOperandRep!(long, int) == long));
static assert(is(CommonOperandRep!(ulong, uint) == ulong));
static assert(is(CommonOperandRep!(long, ulong) == void));
static assert(is(CommonOperandRep!(ulong, long) == void));

string code(MixedDomainKind k) @safe pure nothrow @nogc
{
    final switch (k)
    {
        case MixedDomainKind.naturalSigned: return "S";
        case MixedDomainKind.naturalUnsigned: return "U";
        case MixedDomainKind.ambiguous: return "M";
    }
}

void printMatrix(alias Domain)(string label)
{
    import std.stdio : write, writeln;
    writeln(label);
    static foreach (A; Reps)
    {
        static foreach (B; Reps)
            write(code(Domain!(A, B)));
        writeln();
    }
}

void main()
{
    import std.stdio : writeln;
    writeln("Rep order: byte ubyte short ushort int uint long ulong");
    writeln("S=signed long candidate, U=ulong candidate, M=mixed-domain unresolved");
    printMatrix!AddCheckedDomain("ADD");
    printMatrix!SubCheckedDomain("SUB");
    printMatrix!MulCheckedDomain("MUL");
}
