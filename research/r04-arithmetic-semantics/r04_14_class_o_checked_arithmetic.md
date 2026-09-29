# R04.14 — Class-O checked integral arithmetic

## Purpose

Re-audit the deferred Class-O arithmetic extension against the current M3
production architecture.

R04.2.4 already selected the architectural direction:

- direct integral operators exist only for Class W, where a built-in ResultRep
  proves the complete mathematical result range is representable;
- Class O has no unchecked direct operator;
- an eventual named checked operation is the preferred extension.

R04.14 does not reopen that decision. It determines the minimum correct
value-dependent checked model now that Class-W +, -, scalar multiplication,
exact scalar division, Quantity product, and Quantity quotient semantics have
been promoted.

## Research invariant

> If a direct integral quantities-d arithmetic operator compiles, overflow is
> impossible for every value representable by the operand Reps.

R04.14 must preserve this invariant. Checked operations supplement direct
operators; they do not weaken them.

## Questions

1. What ResultRep should a checked Class-O operation return?
2. Is one runtime failure state, `overflow`, sufficient for +, -, and integral
   multiplication once semantic validity has already passed compile-time gates?
3. Can add/sub/mul share one result carrier without hiding operation-specific
   semantics?
4. Can overflow be detected without performing an overflowing D operation?
5. Can the implementation remain CTFE-capable and `@safe pure nothrow @nogc`?
6. Does optimized code remain competitive with explicit hand-written checked
   integer arithmetic?
7. Which existing M3 U128/S128/range machinery can be reused without turning
   quantities-d into a general checked-integer library?

## Scope

Initial scope:

- same-Spec integral Quantity addition where the Spec is already additive;
- same-Spec integral Quantity subtraction where the Spec already admits it;
- Quantity x integral scalar where scalar multiplication is already valid;
- Quantity x Quantity only after its existing Product semantic relation resolves
  a valid ResultSpec.

Out of scope for the first probes:

- floating arithmetic;
- division (already has exact/inexact/divisionByZero semantics);
- rounded arithmetic;
- arbitrary precision;
- public 128-bit storage Reps;
- automatic dimensionless semantics;
- changing Class-W operator behavior.

## Result-Rep hypotheses

R04.14 must not assume that Class O means "always return long" or "always return
the left Rep".

Three hypotheses need evidence.

### H1 — widest existing operand/result-domain Rep

The checked operation returns the widest built-in Rep that is semantically
natural for the operand pair even though that Rep cannot contain the complete
operation range.

Examples:

- long + long -> checked long
- ulong + ulong -> checked ulong
- long * long -> checked long
- ulong * ulong -> checked ulong

This is attractive because success preserves ordinary built-in storage and
overflow remains value-dependent.

### H2 — operation-specific common Rep

Mixed signed/unsigned pairs may require a different built-in Rep from either
operand to represent all *successful* values of interest. The selection rule
must be explicit and independent of D's native promotion rules.

### H3 — some pairs remain unavailable

If no built-in Rep gives coherent success semantics without surprising loss,
the checked operation may remain compile-time unavailable. Named checked
arithmetic is not required to admit every pair.

## Runtime-state hypothesis

For +, -, and multiplication, after semantic validity and ResultRep selection
are compile-time gates, the minimal runtime state should be:

- value;
- overflow.

There is no `inexact` state for integral +, -, or multiplication: the
mathematical result is integral. There is no division-by-zero state.

This is a hypothesis to prove, not yet a production API commitment.

## Boundary matrix

Each probe must test successful values immediately adjacent to failures.

| Operation | Reps | Required boundaries |
| --- | --- | --- |
| add | long,long | max+0 success; max+1 overflow; min+0 success; min+(-1) overflow |
| add | ulong,ulong | max+0 success; max+1 overflow |
| sub | long,long | min-0 success; min-1 overflow; max-0 success; max-(-1) overflow |
| sub | ulong,ulong | 0-0 success; 0-1 overflow; max-0 success |
| mul | long,long | max*1 success; max*2 overflow; min*1 success; min*(-1) overflow; min*0 success |
| mul | ulong,ulong | max*1 success; max*2 overflow; max*0 success |
| add/sub/mul | long,ulong and ulong,long | sign-boundary and width-boundary cases; ResultRep rule unresolved |

Also test narrower Class-O pairs if the production ResultRep oracle classifies
them as Class O, rather than assuming only 64-bit operands matter.

## Probe sequence

### Probe 1 — classify the Class-O surface

Enumerate all ordered pairs of the eight built-in integral Reps for AddRep,
SubRep, and MulRep. Record exactly which pairs are Class W and Class O.

Goal: establish the real problem size before designing runtime machinery.

### Probe 2 — candidate checked ResultRep

Evaluate H1-H3 against every Class-O pair. Compare the candidate result domain
with an independent mathematical oracle.

Goal: select a deterministic ResultRep rule or prove that some pairs must remain
unsupported.

### Probe 3 — overflow predicate

Implement operation-specific predicates that decide whether the mathematical
result fits ResultRep without first executing an overflowing operation.

Goal: DMD/LDC agreement, boundary correctness, no UB/wrap-dependent semantics.

### Probe 4 — Quantity-shaped carrier

Wrap the predicates in a minimal experimental Quantity-shaped checked result.

Goal: CTFE and `@safe pure nothrow @nogc`; no production API naming decision.

### Probe 5 — semantic integration

Apply the mechanism to already-established Spec/product semantic gates.

Goal: prove representation checking remains independent from semantic validity.

### Probe 6 — code generation

Compare optimized DMD/LDC code with explicit hand-written checked arithmetic.

Goal: quantify cost before any zero-overhead/performance claim.

## Promotion gate

R04.14 is promotable only if:

- ResultRep behavior is deterministic for every admitted pair;
- successful values are mathematically exact;
- overflow is detected before unsafe/wrapping arithmetic can define semantics;
- DMD 2.111 and LDC 1.41 agree;
- CTFE and `@safe pure nothrow @nogc` are demonstrated;
- Class-W operators remain unchanged;
- compile-negative tests cover unsupported pairs;
- code-generation cost is measured;
- production API remains quantity-focused rather than exposing a generic
  checked-integer subsystem.


## Probe 1 result — Class-O surface

Verified locally on x86_64 with both baseline compilers:

- DMD 2.111.0: PASS
- LDC 1.41.0: PASS
- identical output on both compilers.

For each of addition, subtraction, and multiplication:

- 36 of 64 ordered Rep pairs are Class W;
- 28 of 64 ordered Rep pairs are Class O;
- the W/O classification matrix is identical across all three operations.

With Rep order `byte ubyte short ushort int uint long ulong`, every operation
printed:

```text
WWWWWWOO
WWWWWWOO
WWWWWWOO
WWWWWWOO
WWWWWWOO
WWWWWWOO
OOOOOOOO
OOOOOOOO
```

Therefore, under the current production ResultRep oracle:

> An integral +, -, or * pair is Class O exactly when at least one operand Rep
> is `long` or `ulong`.

There are no Class-O islands among the six Reps from `byte` through `uint`.

This substantially narrows Probe 2. The checked ResultRep problem is a
64-bit-boundary problem, not a general 8x8 promotion problem.

### Consequence for Probe 2

Probe 2 must still examine all 28 ordered Class-O pairs, but they fall into a
small number of structural families:

1. `long` with signed <=32-bit;
2. `long` with unsigned <=32-bit;
3. `ulong` with signed <=32-bit;
4. `ulong` with unsigned <=32-bit;
5. `long,long`;
6. `long,ulong` and `ulong,long`;
7. `ulong,ulong`.

Addition and multiplication are mathematically symmetric, but subtraction is
ordered. ResultRep selection must therefore be proven per operation even though
Probe 1 happened to produce the same W/O bitmap.


## Probe 2 result — checked ResultRep domain split

Verified locally on x86_64 with both baseline compilers:

- DMD 2.111.0: PASS
- LDC 1.41.0: PASS
- identical matrices on both compilers.

Probe 2 classified candidate checked result domains as:

- `S`: signed 64-bit candidate (`long`);
- `U`: unsigned 64-bit candidate (`ulong`);
- `M`: no single natural built-in 64-bit result domain under the tested
  hypothesis.

The full matrices were:

```text
ADD / MUL
SSSSSSSM
SUSUSUSU
SSSSSSSM
SUSUSUSU
SSSSSSSM
SUSUSUSU
SSSSSSSM
MUMUMUMU

SUB
SSSSSSSM
SSSSSSSM
SSSSSSSM
SSSSSSSM
SSSSSSSM
SSSSSSSM
SSSSSSSM
MMMMMMMM
```

Only the 28 Class-O cells from Probe 1 are relevant to R04.14.

### Addition and multiplication

For Class-O pairs:

- `long` with signed <=32-bit -> natural checked `long`;
- `long` with unsigned <=32-bit -> natural checked `long`;
- `ulong` with unsigned <=32-bit -> natural checked `ulong`;
- `long,ulong` and `ulong,long` -> mixed-domain unresolved;
- `long,long` -> natural checked `long`;
- `ulong,ulong` -> natural checked `ulong`.

The remaining signed-small/`ulong` ordered pairs are mixed-domain under this
hypothesis because their mathematical result set contains both negative values
and positive values above `long.max`.

Thus mixed-domain ambiguity is not limited to the literal `long/ulong` pair;
a full-width `ulong` combined with any signed operand can expose both sides of
the built-in 64-bit signed/unsigned boundary.

### Subtraction

Subtraction is more restrictive because operand order and negative results
matter.

- Class-O cases involving `long` but no `ulong` have a natural checked
  `long` domain.
- Every Class-O case involving `ulong` is mixed-domain under the tested
  hypothesis.

In particular, even `ulong - ulong` spans negative mathematical results and
positive values up to `ulong.max`; neither `long` nor `ulong` alone
preserves that complete natural success set.

### Key conclusion

Class O splits into at least two semantic categories:

1. **O64** — a natural built-in 64-bit ResultRep exists and runtime overflow is
   sufficient;
2. **OM** — the mathematical result domain crosses the `long`/`ulong`
   representability boundary, so choosing either built-in type would classify
   otherwise representable mathematical results as failure.

This is not merely an implementation issue. It is a public semantic choice.

Therefore R04.14 must not yet promote a universal `value | overflow` carrier
for every Class-O pair.

### Next probe

Probe 3 should focus on O64 first:

- checked long addition/subtraction/multiplication;
- checked ulong addition/multiplication;
- mixed-width Class-O pairs that resolve naturally to one of those domains.

It should prove overflow predicates on original operand values, CTFE, and
`@safe pure nothrow @nogc`.

OM should remain separately classified and compile-time unavailable during that
probe. A later probe can decide whether OM deserves a wider tagged result,
128-bit internal/result representation, or simply remains unsupported.
