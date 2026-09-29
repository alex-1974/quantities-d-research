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


## Probe 3 result — O64 overflow predicates

Verified locally on x86_64 with both baseline compilers:

- DMD 2.111.0: PASS
- LDC 1.41.0: PASS

The prototype demonstrates for the tested O64 domains:

- representability is checked before the potentially overflowing operation;
- `long.min` and `long.max` boundary cases behave as expected;
- signed magnitude handling admits `long.min * 1` and rejects
  `long.min * -1`;
- unsigned max boundaries behave as expected;
- mixed-width O64 examples work;
- the implementation is usable at CTFE;
- the prototype compiles as `@safe pure nothrow @nogc`.

This proves feasibility, not completeness.

Before a Quantity-shaped API probe, the predicates require an independent
adversarial oracle. Probe 4 will compare their classification and successful
values against exact `BigInt` arithmetic over systematic boundary sets.
`BigInt` is research-only oracle machinery and is not proposed for production.


## Probe 4 result — adversarial exact oracle

Verified locally on x86_64:

- DMD 2.111.0: PASS — 917 exact-oracle comparisons;
- LDC 1.41.0: PASS — 917 exact-oracle comparisons;
- total observed comparisons across both compiler runs: 1,834;
- no classification or successful-value mismatch.

The research-only `BigInt` oracle independently checked both:

1. success versus overflow classification;
2. exact returned value whenever the fixed-width predicate admitted success.

The tested boundary sets include signed and unsigned endpoints, adjacent values,
zero, small magnitudes, half-range values, and the signed/unsigned 64-bit
transition.

This materially strengthens the O64 result: the portable precondition
predicates are not merely plausible on hand-picked examples; they agree with
exact mathematical arithmetic over the systematic adversarial set on both
baseline compilers.

It does not prove all possible 64-bit values exhaustively, so the production
promotion gate still requires direct reasoning/tests for each predicate.

## Next step — Quantity-shaped integration

Probe 5 may now wrap O64 in a minimal Quantity-shaped checked operation while
preserving the existing M3 architecture:

- Class-W direct operators remain unchanged;
- Class-O checked arithmetic is named, never an unchecked direct operator;
- semantic validity is resolved before representation/runtime checking;
- same-Spec addition/subtraction retain their existing semantic gate;
- scalar multiplication retains Quantity Spec;
- Quantity x Quantity multiplication must resolve ProductResultSpec before
  applying O64 representation logic;
- OM remains compile-time unavailable.

The probe should test API shape, CTFE, attributes, and compile-negative OM /
semantic-invalid cases. It is still research and must not modify production.


## Probe 5 result — Quantity-shaped checked API

Verified locally on x86_64:

- DMD 2.111.0: PASS;
- LDC 1.41.0: PASS.

The prototype demonstrates that named checked O64 arithmetic can be integrated
with the current Quantity architecture without weakening Class-W direct
operators.

Validated research shape:

- `checkedAdd` for semantically valid additive Quantities;
- `checkedSub` for semantically valid subtractive Quantities;
- `checkedMul` for scalable Quantity x integral scalar;
- `checkedMul` for Quantity x Quantity after ProductResultSpec resolution;
- result carrier `value | overflow`;
- OM combinations remain compile-time unavailable;
- semantically invalid Spec combinations remain compile-time unavailable;
- CTFE and `@safe pure nothrow @nogc` are preserved.

The names are intentionally distinct from `exactMul`. Current production
`exactMul` expresses exact canonical rescaling and can fail with
`ProductFailure.inexact`; checked Class-O multiplication expresses
value-dependent representability and can fail with overflow. Those failure
dimensions must not be conflated accidentally.

### R04.14 O64 core conclusion

The unscaled O64 core is now supported by five layers of evidence:

1. complete Class-W/Class-O surface classification;
2. natural O64 versus mixed-domain separation;
3. portable pre-overflow predicates;
4. independent exact BigInt oracle audit;
5. Quantity-shaped semantic/API integration on DMD and LDC.

The preferred research architecture remains:

> direct integral operators are available only for Class W; Class O may gain
> explicit named checked operations where a natural built-in ResultRep exists.

This preserves the existing operator invariant while admitting useful
value-dependent 64-bit arithmetic.

### Still open

R04.14 has not yet established production semantics for:

1. **OM mixed-domain arithmetic** — cases whose natural mathematical result set
   crosses the `long`/`ulong` boundary;
2. **checked multiplication with non-1/1 canonical rescale** — interaction
   between overflow and `ProductFailure.inexact`;
3. final public carrier/type naming and export placement;
4. optimized code generation versus compiler intrinsics / hand-written checked
   arithmetic;
5. production negative-test matrix and documentation.

These should remain separate research questions. In particular, solving
rescaling must not be used to smuggle in an OM policy, and solving OM must not
change the proven O64 core.


## Probe 6 result — OM exact result domains

Verified locally on x86_64 with identical output from DMD 2.111.0 and
LDC 1.41.0.

Representative exact ranges:

- `int + ulong`: [-2147483648, 18446744075857035262]
- `long + ulong`: [-9223372036854775808, 27670116110564327422]
- `int * ulong`:
  [-39614081257132168794624491520,
    39614081238685424720914939905]
- `long * ulong`:
  [-170141183460469231722463931679029329920,
    170141183460469231704017187605319778305]
- `ulong - ulong`:
  [-18446744073709551615, 18446744073709551615]
- `long - ulong`:
  [-27670116110564327423, 9223372036854775807]
- `ulong - long`:
  [-9223372036854775807, 27670116110564327423]

Every audited OM range fits neither `long` nor `ulong`.

### Consequence

OM is not merely an O64 operation that needs a wider temporary for overflow
detection. The mathematical success domain itself crosses the built-in
64-bit signed/unsigned boundary.

Therefore choosing `long` or `ulong` as the public checked ResultRep would
introduce an additional representation policy: some mathematically valid
results that fit the other 64-bit interpretation would be reported as
overflow solely because of the selected public domain.

For multiplication the issue is stronger. Mixed `long * ulong` reaches a
range close to the signed 128-bit endpoints, so a faithful fixed-width result
domain is genuinely wider than 64 bits.

### R04.14 OM conclusion

The O64 `value | overflow` model must not be generalized mechanically to OM.

The conservative quantities-d policy is:

> OM remains compile-time unavailable unless quantities-d deliberately adopts
> a wider public integral representation policy.

An internal 128-bit helper is insufficient justification for such a public
policy. Public 128-bit Reps, a tagged signed/unsigned result, arbitrary
precision, or another widened representation would each be separate API and
ABI decisions and are outside the current M3 scope.

This conclusion preserves the library's existing built-in-Rep model and avoids
turning Class-O support into a general extended-integer subsystem.


## Probe 7 result — checked rescale state semantics

Verified locally on x86_64 with DMD 2.111.0 and LDC 1.41.0.

Both compilers passed the exact-oracle state model:

- `exact`
- `inexact`
- `overflow`

The classification is defined by the mathematical final result, not by
fixed-width evaluation order:

1. if the rational result is non-integral -> `inexact`;
2. otherwise, if the exact integer is outside ResultRep -> `overflow`;
3. otherwise -> `exact`.

Consequently, an intermediate wider than ResultRep is not itself overflow.
For example, `long.max * 2 / 2` is exact `long.max`.

This establishes the semantic target for a fixed-width implementation.


## Probe 8 result — fixed-width checked rescale kernel

Verified locally on x86_64:

- DMD 2.111.0: PASS — 23,716 exact-oracle comparisons;
- LDC 1.41.0: PASS — 23,716 exact-oracle comparisons;
- total observed comparisons across both runs: 47,432;
- no status or exact-value mismatch.

The candidate kernel uses no BigInt, allocation, or public widened integer
representation. It is CTFE-capable and `@safe pure nothrow @nogc`.

Validated algorithm:

1. separate sign and unsigned operand magnitudes;
2. cross-cancel the denominator against lhs magnitude, rhs magnitude, and the
   canonical-rescale numerator;
3. if a denominator remains, classify the mathematical result as `inexact`;
4. select the final ResultRep magnitude limit from the result sign;
5. prove each remaining multiplication against that final limit before
   evaluating it;
6. classify a proven-too-large exact integer as `overflow`;
7. otherwise construct the exact ResultRep, including `long.min`.

This correctly distinguishes final-result overflow from intermediate-width
artifacts. In particular, cases such as `long.max * 2 * 3 / 6` remain exact.

### Consequence

For signed O64 product results, canonical rescaling does not require BigInt or
a wider public Rep to support the runtime state model

    exact | inexact | overflow

A fixed-width, allocation-free implementation is feasible.

This is algorithmic evidence, not yet a production API decision. Remaining
work before promotion includes:

- final public result carrier and naming;
- unsigned O64 rescaled-product symmetry where applicable;
- Quantity-shaped rescaled checked API integration;
- negative compile-contract matrix;
- DMD/LDC optimized codegen and performance comparison;
- production documentation and Fast Gate.


## Probe 9 result — operation-specific result carriers

Verified locally on x86_64 with DMD 2.111.0 and LDC 1.41.0.

Both compilers passed the carrier/API prototype with CTFE and
`@safe pure nothrow @nogc`.

Preferred public state spaces:

- unscaled checked O64 arithmetic: `value | overflow`;
- checked rescaled product: `exact | inexact | overflow`;
- existing exact division remains:
  `exact | inexact | divisionByZero`.

### Carrier policy

Do not introduce a universal public `ArithmeticStatus`.

The public failure/status vocabulary should remain as narrow as the operation's
actual semantics. A generic value-or-failure implementation mechanism may be
private/internal where useful, but it must not broaden public state spaces.

This is consistent with the existing M3 separation between
`ProductResultValue` and `DivisionResult`.

Default-constructed carriers must remain failure states and must never
fabricate a successful value.

### Remaining promotion work

The semantic/API research is now sufficiently constrained to move to the
performance gate. Before production promotion, compare optimized DMD/LDC
code generation for:

- signed/unsigned checked add;
- signed/unsigned checked subtract where applicable;
- signed/unsigned checked multiply;
- the cross-cancelled checked rescale kernel.

Compiler intrinsics or checked-integer helpers are optimization candidates
only. They must not define different semantics from the portable reference
implementation.
