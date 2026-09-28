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
