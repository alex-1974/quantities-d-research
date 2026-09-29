# R04.13 — Quantity Division and Dimensionless Semantics

Status: research, not production API.

## Purpose

Determine the semantic and numerical contract for `Quantity / Quantity` after
the promoted M3 product architecture.

Division must preserve the established separation:

1. Spec algebra selects semantic meaning.
2. Dimension algebra determines the physical quotient dimension.
3. Unit/scale algebra determines the exact mathematical quotient unit and its
   scale relative to the result Spec's CanonicalUnit.
4. Rep algebra determines whether the numeric operation is representable and
   whether a runtime failure state is required.

A quotient Dimension does not by itself determine a result Spec.

## Primary semantic matrix

| Operation | Mechanical Dimension | Semantic observation | Initial classification |
|---|---|---|---|
| `Length / Length` | `Dimensionless` | many distinct dimensionless meanings are possible | explicit result relation required |
| `Area / Length` | `Length` | physical dimension matches Length, but semantic ownership still matters | explicit relation candidate |
| `Length / Area` | `Length^-1` | no current standard Spec | explicit consumer/domain Spec required |
| `Length / Time` | `Length Time^-1` | Velocity is plausible but not implied by Dimension alone | explicit Velocity relation required |
| foreign Spec / foreign Spec | quotient Dimension | neither operand can own consumer semantics | external relation provider required if supported |

## Scalar division is a separate operation class

`Quantity / scalar` and `Quantity / Quantity` are not the same semantic
operation.

For scalar division, the scalar contributes no physical Dimension, Unit, or
Spec. The result therefore retains the original Quantity Spec and Dimension:

```text
Length / 2 -> Length
10 m / 2 -> 5 m
```

By contrast, Quantity/Quantity division performs Dimension and Unit algebra:

```text
Length / Length -> Dimensionless physical Dimension
10 m / 2 m -> dimensionless result
```

A raw numeric scalar such as `2` must not be modeled implicitly as a
`Quantity` with a dimensionless Spec merely to unify these operator paths.
The existing scalar-division semantics remain a distinct operation class.
R04.13 studies Quantity/Quantity division unless explicitly stated otherwise.

## Dimensionless is not a Spec

`Dimensionless` is the multiplicative identity of physical Dimension algebra.
It is not a universal semantic quantity specification.

Dimensionless physical results can represent semantically different concepts.
Therefore `DivideDimension!(A.Dimension, B.Dimension) == Dimensionless` must
not automatically select a generic result Spec or a raw scalar.

Research must determine whether quantities-d needs a deliberately generic
ratio-like Spec at all. Such a Spec may be useful only when the consumer
explicitly chooses that semantic meaning.

## Candidate semantic resolver

The product architecture suggests, but does not yet promote, ordered quotient
hooks:

```d
Lhs.QuotientWith!Rhs
Rhs.QuotientFromLeft!Lhs
```

Resolution would preserve operand order. If both hooks exist, they must agree.
The selected Spec must be valid and satisfy:

```d
is(ResultSpec.Dimension ==
   DivideDimension!(Lhs.Dimension, Rhs.Dimension))
```

For foreign Specs, the corresponding explicit relation-provider shape to probe
is:

```d
Relations.Quotient!(LhsSpec, RhsSpec)
```

An explicit provider should be authoritative, with no silent fallback to
operand-owned hooks, matching the promoted product rule.

## Unit and canonical-storage question

The mathematical quotient unit is:

```d
DivideUnit!(LhsSpec.CanonicalUnit, RhsSpec.CanonicalUnit)
```

The exact rescale into result canonical storage is therefore the quotient of
that mathematical unit and `ResultSpec.CanonicalUnit`.

This scale is independent of semantic resolution. Matching dimensions do not
imply matching scales.

## Integral numerical problem

Integral `Quantity / Quantity` is not a total direct operator in the general
case:

- the denominator value may be zero;
- the mathematical quotient may be non-integral;
- canonical rescaling may itself be rational;
- signed extrema require the same care already established for scalar
  `exactDiv`.

Consequently a raw integral `/` operator is not an initial production
candidate. The first numerical probe should be an exact named operation with
explicit `divisionByZero` and `inexact` outcomes.

The existing scalar `exactDiv` result semantics are evidence, not permission
to reuse the implementation or result type blindly: Quantity/Quantity division
also changes Spec, Dimension, and Unit.

## Research questions

1. Is an operand-owned quotient resolver structurally sound and sufficiently
   distinct from product resolution?
2. Is an external `Relations.Quotient` provider needed for the same foreign
   Spec case established by R04.12?
3. Should quantities-d provide any generic dimensionless semantic Spec, or only
   the Dimensionless physical dimension?
4. What exact canonical-rescale formula and cancellation order avoids
   intermediate overflow?
5. What Rep can safely hold the exact quotient after canonical rescaling?
6. Which failure states are reachable after compile-time range gating?
7. Can the exact operation remain CTFE-capable, `@safe`, `pure`, `nothrow`,
   and `@nogc`?
8. What negative compile gates are required for missing/conflicting/wrong-
   dimension semantic relations?
9. Does any direct `/` operator satisfy the existing total-safety invariant
   for integral Reps? Initial expectation: no, because zero is representable.

## First probes

1. semantic resolver only: owned quotient hooks and conflict diagnostics;
2. external relation provider and authoritative/no-fallback behavior;
3. exact unit/canonical-rescale algebra for quotient results;
4. integral exact quotient kernel with zero and inexact cases;
5. signed/unsigned and extrema matrix on DMD 2.111 and LDC 1.41;
6. CTFE and attribute checks;
7. only after those results, evaluate public API shape.

## Promotion gate

No production Quantity/Quantity division API should be promoted until the
research establishes:

- explicit result-Spec semantics;
- physical Dimension validation;
- exact Unit/canonical-storage scaling;
- a proven Rep/result policy;
- zero, inexact, and overflow reachability;
- negative compile behavior;
- DMD/LDC baseline agreement;
- CTFE/UFCS/attribute contracts;
- consumer justification for any standard dimensionless Spec.


## Probe 1 result — semantic resolver shape

The isolated compile-time resolver probe supports the proposed ordered shape:

- `Lhs.QuotientWith!Rhs` resolves a forward operand-owned relation;
- `Rhs.QuotientFromLeft!Lhs` resolves the same ordered operation from the
  divisor side;
- two non-void operand-owned relations must agree;
- no relation resolves to `void`;
- `Relations.Quotient!(Lhs, Rhs)` can express relations between two foreign
  Specs;
- external relations are ordered and are not automatically swapped;
- an explicit external provider is authoritative and does not silently fall
  back to operand-owned hooks.

This is structural evidence only. The probe intentionally does not yet validate
that a selected result Spec has
`DivideDimension!(Lhs.Dimension, Rhs.Dimension)`; that validation is the next
probe and must use the promoted canonical Dimension algebra rather than local
placeholder semantics.


## Probe 3 result — quotient Unit and canonical rescale

The Unit/scale probe isolates the exact scale relation

```text
MathematicalUnit = Lhs.CanonicalUnit / Rhs.CanonicalUnit
CanonicalRescale = MathematicalUnit / ResultSpec.CanonicalUnit
```

Representative exact results:

| Mathematical quotient | Result canonical unit | Exact rescale |
|---|---|---:|
| m / m | unit ratio | 1 |
| km / m | unit ratio | 1000 |
| m / km | unit ratio | 1/1000 |
| km / h | m/s | 5/18 |
| km / h | km/h | 1 |
| m / km² | 1/m | 1/1,000,000 |
| m / km² | 1/km | 1/1000 |

This confirms that Dimension validation and Unit scaling are independent.
A physically valid quotient may still require a non-integral exact canonical
rescale.

For integral Quantity/Quantity division the numerical kernel should therefore
model the complete rational expression rather than first performing integer
division and then applying a scale. Conceptually:

```text
(lhsCanonical * scaleNumerator)
--------------------------------
(rhsCanonical * scaleDenominator)
```

The next probe must investigate cross-cancellation before multiplication and
division, zero-denominator handling, signed extrema, and which result Rep can
represent an exact integral result without intermediate overflow.


## Probe 4 — exact scaled integral quotient kernel

The first bounded-magnitude kernel evaluates the complete rational expression

```text
lhs * scaleNumerator
--------------------
rhs * scaleDenominator
```

by separating sign from unsigned magnitude and cross-cancelling numerator and
denominator factors before multiplication.

The probe covers:

- exact, inexact, and division-by-zero results;
- positive and negative operands;
- `long.min` without evaluating `-long.min`;
- the mathematical `long.min / -1 == 2^63` magnitude;
- cancellation that prevents otherwise overflowing intermediate products;
- the `5/18` km/h -> m/s rescale;
- rational canonical rescale such as `1/1000`;
- a non-cancellable bounded-intermediate overflow case;
- CTFE plus `@safe pure nothrow @nogc` on the probe kernel.

### Current conclusion

Cross-cancellation is necessary but does not by itself prove that all admitted
quotients fit a fixed bounded intermediate representation.

Unlike the current product path, R04.13 has not yet established a compile-time
range gate that makes runtime quotient overflow unreachable. Therefore
`overflow` must remain a live research outcome for Quantity/Quantity exact
division until the Rep/range probe proves otherwise.

The magnitude `2^63` from `long.min / -1` also demonstrates why arithmetic
correctness and result-Rep admissibility remain separate gates.


## Probe 5 — Result Rep versus intermediate range

The Rep/range probe separates two questions that must not be conflated:

1. can the final exact quotient be represented by the selected ResultRep?
2. can the scaled rational expression be evaluated exactly without overflowing
   the chosen intermediate representation?

A wider ResultRep does not automatically solve (2). Cross-cancellation can
turn an apparently overflowing expression into a small exact one, while a
non-cancellable scale numerator can still exceed a bounded intermediate domain.

### Direct integral division

Ordinary built-in integral divisor Reps contain zero. Therefore a direct
Quantity/Quantity `/` operation cannot satisfy the existing total-safety
invariant over the complete operand Rep domains:

```text
if an integral quantities-d arithmetic operator compiles,
it is valid for every value representable by its operand Reps
```

Division-by-zero alone disproves totality. A future stronger non-zero divisor
type could change that premise, but R04.13 does not introduce such a type.

This strengthens the initial direction: integral Quantity/Quantity division
belongs on a named exact/checked operation, not an unchecked direct `/`
operator.

### Failure-state consequence

`divisionByZero` remains intrinsically reachable for ordinary integral RHS
Reps and cannot be compiled away by a range proof.

`overflow` is different. It may eventually become unreachable if research
finds an exact intermediate strategy and a ResultRep proof that cover every
admitted call. That proof does not yet exist, so the status remains live in
research.

The existing scalar `QuotientRep` rule is useful evidence for signed extrema
but is insufficient by itself for scaled Quantity/Quantity quotients.


## Probe 6 — factorized exact evaluation

A stronger exact-integral algorithm does not need to form either full rational
intermediate product.

For

```text
a * n
-----
b * d
```

where `a/b` are operand magnitudes and `n/d` is the exact canonical
rescale, cancel every numerator factor against every denominator factor first.

After complete pairwise cancellation:

- if either remaining denominator factor is not `1`, the mathematical result
  is not an integer and the operation is `inexact`;
- otherwise the exact result is the remaining `a * n`;
- before forming that one product, compare `n <= ResultLimit / a`.

This means a dedicated wider rational intermediate is not inherently required
for exact integral Quantity/Quantity division.

### Refined failure model

The earlier Probe 4 `overflow` outcome was a property of its eager bounded
intermediate algorithm, not necessarily of the operation semantics.

With factorized evaluation, the meaningful outcomes become:

```text
exact
inexact
divisionByZero
resultOutOfRange
```

Whether `resultOutOfRange` should exist in the public result domain is still a
Rep-policy question. If a compile-time ResultRep rule can guarantee that every
exact result admitted by the API fits, it can be removed just as product
overflow was removed. If not, it remains a genuine runtime result.

Witnesses include:

- `long.min / 1`: exact and representable in signed long;
- `long.min / -1`: exact mathematical magnitude `2^63`, outside signed
  long but representable in a suitable wider/unsigned magnitude domain;
- large factors that cancel completely before multiplication;
- large non-cancellable scale factors that produce a genuinely out-of-range
  final exact result.

The next Rep-policy probe should therefore focus on final-result bounds, not on
constructing a universally wider intermediate integer.
