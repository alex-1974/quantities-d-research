# R04.11 — Derived dimensions, units, and open Spec algebra

Status: research probe; no production API decision.

## Goal

Test the minimum architecture needed for derived quantities without turning quantities-d
into a catalogue of every physical quantity.

Reference relations:

- Length * Length -> Area
- Length / Time -> Velocity
- Velocity / Time -> Acceleration

Canonical-unit reference relations:

- m * m -> m^2
- m / s -> m/s
- (m/s) / s -> m/s^2

## Hard invariants

1. Dimension algebra, Unit/Scale algebra, Spec algebra, and Rep algebra are separate.
2. Equal dimensions do not imply equal Specs or equal Units.
3. Every Spec owns a concrete CanonicalUnit.
4. A derived operation first has a mathematical result unit determined from the
   operand canonical units.
5. That mathematical result unit must be compatible with the result Spec's
   CanonicalUnit.
6. If the scales differ, the result must be converted; the raw numeric result
   must never simply be reinterpreted in the result CanonicalUnit.
7. Unit scales remain exact rational values as long as the existing ExactRatio
   model can represent the operation.
8. Consumer-defined Specs and relations must not require editing quantities-d.
9. Semantic relations are explicit. Dimension equality alone must never invent
   a semantic result Spec.
10. Runtime registries or per-value unit metadata are out of scope.

## Why Area alone is insufficient

Length * Length with canonical metre operands naturally produces square metre,
so a scale bug can remain hidden because the result scale is 1.

A stronger probe deliberately chooses a result Spec whose CanonicalUnit has the
same dimension but a different scale.

Example:

    3 m * 4 m = 12 m^2 = 0.000012 km^2

If a candidate design stores 12 directly in an Area-in-km^2 result, it is
semantically wrong even though all dimensions match.

Acceleration gives the same class of requirement:

    Acceleration dimension: L T^-2
    canonical unit (normal case): m/s^2

km/s^2 has the same dimension, but Scale = 1000 relative to m/s^2.

## Probe model

The research implementation should model four independent compile-time
questions:

    ResultSpec = MulResult!(LhsSpec, RhsSpec)
    ResultDim  = MulDimension!(LhsSpec.Dimension, RhsSpec.Dimension)
    MathUnit   = MulUnit!(LhsSpec.CanonicalUnit, RhsSpec.CanonicalUnit)
    ResultRep  = MulRep!(LhsRep, RhsRep)

and analogously for division.

Then require:

    ResultSpec.Dimension == ResultDim
    MathUnit.Dimension    == ResultDim
    ResultSpec.CanonicalUnit.Dimension == ResultDim

Finally compare:

    MathUnit.Scale
    ResultSpec.CanonicalUnit.Scale

A scale of 1 permits direct storage. Any other ratio requires the same kind of
checked/exact conversion reasoning already established by M1.

## Open customization requirement

The core must not contain a closed table such as:

    Length * Length -> Area
    Force * Length  -> Energy
    ...

A consumer must be able to add its own Specs and semantic relations without
forking quantities-d. Candidate mechanisms must therefore be tested for:

- relations declared by the left Spec;
- relations declared by the right Spec for interaction with an existing Spec;
- an external relation/customization mechanism that can live entirely in a
  consumer module.

The probe must reject a mechanism if an external consumer cannot express a
useful relation involving existing quantities-d types.

## Required positive probes

1. Length[m] * Length[m] -> Area[m^2], scale 1.
2. Length[m] / Time[s] -> Velocity[m/s], scale 1.
3. Velocity[m/s] / Time[s] -> Acceleration[m/s^2], scale 1.
4. Consumer-defined result with canonical km^2:
   Length[m] * Length[m] -> ConsumerArea[km^2], requiring scale conversion.
5. Exact scale derivation:
   mm^2 relative to m^2 = 1 / 1_000_000.
6. Exact scale derivation:
   km/h relative to m/s = 5 / 18.

## Required negative probes

- Same dimension but no semantic relation: operation rejected.
- Semantic result declares the wrong result dimension: rejected at compile time.
- Derived mathematical unit dimension disagrees with ResultSpec.Dimension:
  rejected at compile time.
- Consumer relation cannot be discovered without modifying quantities-d:
  candidate customization mechanism rejected.
- Integral result requires an inexact canonical-unit rescale: it must not
  silently truncate or reinterpret.

## Non-goals

- Complete SI catalogue.
- Every named derived physical quantity.
- Runtime unit parsing.
- String-based dimension algebra.
- Automatic semantic inference from dimensions.
- Production promotion of Area, Time, Velocity, or Acceleration in this probe.

## Decision gate

Promote nothing until DMD 2.111 and LDC 1.41 demonstrate that one open
customization mechanism can satisfy the probes with CTFE-friendly,
@safe/pure/nothrow/@nogc-compatible compile-time machinery where applicable.

The intended principle is:

> quantities-d supplies algebra and safety; applications may supply their own
> physical vocabulary.
