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
