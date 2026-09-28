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

## Compiler evidence — first open-customization probe

Observed on the user's baseline toolchain with both DMD and LDC:

- positive core probe: PASS
- external consumer probe: PASS
- negative no-relation probe: PASS

The external consumer test is significant because the left-hand Spec is not
modified by the consumer. The consumer-owned right-hand Spec supplies a
`ProductFromLeft!Lhs` hook, and the core dispatcher discovers it successfully
across module boundaries.

This establishes that the two-sided member-hook model is viable in D for at
least this extension shape:

    core/existing lhs  *  consumer-owned rhs  -> consumer-owned result

The negative probe also confirms the intended semantic rule: equal dimensions
alone do not create a multiplication relation.

### What this does not establish yet

The following remain open and require dedicated probes before production use:

- ambiguity when both `Lhs.ProductWith!Rhs` and `Rhs.ProductFromLeft!Lhs`
  provide non-void but different results;
- extension of a relation between two Specs neither of which the consumer owns;
- commutative canonicalization of multiplication relations;
- non-commutative future operations;
- exact result-scale reduction using production `ExactRatio` rather than the
  minimal research `Ratio`;
- integral arithmetic when canonical-unit rescaling is inexact;
- overflow behavior while composing or rescaling large exact ratios;
- interaction with the production `Quantity!(Spec, Rep)` operator machinery.

The present evidence is therefore sufficient to keep the two-sided hook model
as a serious candidate, but not yet sufficient to promote it to the production
API.

## Compiler evidence — conflict handling and orphan-relation limit

Observed with both baseline compilers (DMD and LDC):

- positive core probe: PASS
- external consumer-owned RHS hook: PASS
- conflicting two-sided hooks: correctly rejected at compile time
- missing semantic relation: correctly rejected
- two foreign Specs: current member-hook model exposes the expected extension limit

### Confirmed property: conflict safety

If both operands provide a multiplication relation and the two hooks resolve to
different ResultSpecs, the dispatcher now rejects the program with a compile-time
error instead of silently preferring one side. This is required for deterministic
semantic ownership.

If both hooks resolve to the same ResultSpec, that case remains admissible in the
candidate design.

### Confirmed limitation: orphan relations

A third-party consumer cannot define a natural operator relation between two
pre-existing Specs when it owns neither operand type. Member customization has no
neutral location in which such a relation can be declared.

This is analogous to an orphan-relation problem:

    library A owns SpecA
    library B owns SpecB
    application C wants SpecA * SpecB -> ResultC

With member hooks alone, application C cannot add the relation without wrapping or
modifying one of the operand Specs.

This is now a documented design limitation, not a compiler uncertainty.

### Next research question

Before production promotion, R04.11 must compare candidate third customization
mechanisms that preserve the existing two-parameter Quantity identity:

- explicit algebra/policy module or relation set discovered at compile time;
- UFCS/free-template customization where import lookup can be made deterministic;
- mixin-provided relation declarations;
- opt-in wrapper/context types around arithmetic expressions;
- deliberate acceptance of the orphan-relation restriction.

A central runtime registry, string-based lookup, and adding an Algebra parameter to
`Quantity!(Spec, Rep)` remain outside the preferred design because they would either
add runtime machinery or change type identity/template cost.

## Compiler evidence — relation-set API shapes

Observed with both baseline compilers (DMD and LDC):

- explicit named relation operation: PASS
- relation-scope wrapper with operator syntax: PASS
- runtime unittest execution: PASS

The experiment confirms that an explicit compile-time relation set can solve the
orphan-relation problem without becoming part of `Quantity!(Spec, Rep)` itself.

Two API shapes are viable at the language level:

    multiplyWith!Relations(lhs, rhs)

and a scoped wrapper form equivalent to:

    relations.wrap(lhs) * relations.wrap(rhs)

The first is explicit and simple but loses natural operator syntax. The second
preserves operator syntax inside an explicit local relation context, at the cost
of temporary wrapper types at the expression boundary.

Neither approach requires runtime registration or global mutable state. The
relation-set type can remain compile-time-only.

### Architectural consequence

The orphan-relation problem and ordinary Quantity type identity can therefore be
separated:

- `Quantity!(Spec, Rep)` remains canonical and context-free;
- ordinary relations owned by an operand may continue to use member hooks;
- exceptional third-party relations can be supplied through an explicit
  compile-time relation context;
- a direct bare `lhs * rhs` cannot discover an arbitrary consumer relation set
  unless that context is encoded somewhere visible to overload resolution.

This means the unresolved question is now API policy rather than feasibility:
should quantities-d accept the orphan restriction for ordinary operators and
provide an explicit escape hatch, or should a scoped relation wrapper become a
first-class public mechanism?

## Compiler evidence — integral canonical rescaling

Observed with both baseline compilers (DMD and LDC):

- canonical product with scale 1: classified as total for integral exactness;
- fractional canonical rescale `1 / 1_000_000`: classified as not total;
- reducible ratios are classified after reduction;
- an integer multiplier is total with respect to exactness, while overflow
  remains an independent representation-safety question.

The reference case is:

    canonical lhs: m
    canonical rhs: m
    mathematical product: m²
    result canonical unit: km²
    rescale: 1 / 1_000_000

Selected values can still convert exactly (for example 1_000_000 m² -> 1 km²),
but the direct operator contract is value-independent. Since 1 m² cannot be
represented by an integral km² Rep, the operation is not total for integral
representations.

### R04.11 integral product gate

For a direct integral `Quantity * Quantity` operator to exist, all independent
gates must succeed:

1. semantic gate: a unique ResultSpec exists;
2. dimension gate: ResultSpec.Dimension equals the product dimension;
3. unit gate: mathematical product-unit and ResultSpec.CanonicalUnit have the
   same dimension;
4. representation gate: a built-in ResultRep contains the complete mathematical
   product range;
5. canonical-rescale gate: the reduced mathematical-unit -> canonical-unit
   scale has denominator 1 for integral storage;
6. post-rescale range gate: applying any integer scale multiplier still fits the
   selected ResultRep for every representable operand pair.

Gate 5 is necessary but not sufficient. A scale such as `1_000_000 / 1` is
always exact for integer values but can enlarge the result range, so gate 6 must
be proven together with ResultRep selection.

This extends the existing M3 Class-W rule:

> If an integral quantities-d arithmetic operator compiles, overflow and
> canonical-unit truncation are impossible for every value representable by
> its operand Reps.

### Consequence for fractional rescale

A relation whose canonical rescale is fractional must not silently expose a
direct integral operator. It needs an explicit value-dependent operation using
checked/exact result semantics, analogous in spirit to the existing checked
conversion and `exactDiv` APIs.

The exact public name and result type remain open for later R04 work; this probe
establishes the safety requirement, not the final syntax.

## Compiler evidence — combined product/range proof

The scaled-product range probe now passes on both baseline compilers (DMD and
LDC).

The research oracle computes the complete mathematical endpoint range for the
integral operand product first and treats canonical integer rescaling as part of
the same range problem. The K=1 path preserves the full 128-bit product range;
it does not narrow through an intermediate built-in Rep.

An exhaustive compile-time comparison covers all 64 ordered pairs from:

    byte, ubyte, short, ushort, int, uint, long, ulong

For every pair admitted by the current production MulRep policy, the exact-range
oracle also admits the pair. Representative mixed-width cases whose mathematical
range exceeds all built-in integral Reps are rejected by both models.

This supports the Gate-6 formulation:

> ResultRep selection for integral derived-unit multiplication should be proven
> over the complete mathematical expression, including any exact integer
> canonical rescale, rather than by assuming that a separately selected MulRep
> remains sufficient after rescaling.

The name ScaledMulRep remains research terminology. This evidence does not yet
select a production API or implementation strategy.

The current focused oracle supports K=1 for the full 64x64 product domain and
selected K>1 cases whose unscaled endpoint magnitudes remain within the probe's
explicit rescale precondition. A general 128x64 rescale oracle is not required
to establish the present safety invariant and should only be added if later
research needs it.

## Dimension representation evidence

The dimension-model, open-canonicalization, and structural-semantics probes now
pass on both baseline compilers (DMD and LDC).

The evidence supports separating two concerns:

1. **Canonical native representation**
   Core-created dimensions should normalize their term set before the concrete
   D type is formed. This preserves native type identity for mathematically
   equal dimensions, so common internal gates can use `is(A == B)`.

2. **Structural dimension protocol**
   Dimension semantics can also be recognized by compile-time structure rather
   than nominal ownership. A foreign type that deliberately exposes the
   dimension protocol can participate in semantic equality without inheriting
   from a core type or registering itself in a central table.

The current research model therefore does not require a choice between nominal
and structural semantics. Canonical native dimensions can use cheap nominal
identity, while a structural trait layer can provide an interoperability
boundary for external dimension-like types.

A further important result is that normalization must happen **before** the
concrete dimension type is instantiated. Normalizing only an internal member of
`Dimension!(Terms...)` does not make differently ordered template argument
lists the same D type.

The open canonicalization probe also demonstrates that a core-owned global
`TagRank` table is not inherently required. A tag can instead describe a
stable compile-time ordering key, allowing consumer-defined independent
axes without modifying the quantities-d core. Whether such keys should become
part of the public protocol remains an API decision; the mechanism is proven,
not yet selected.

Open question: measure template-instantiation / compile-time cost of structural
semantic equality versus already-canonical native type identity before choosing
how widely the structural path should be used internally.

### Dimension equality compile-time cost

A scaled compile-time benchmark compared canonical native type identity with
structural semantic equality. Each case instantiated 4096 distinct dimension
queries to prevent one memoized comparison from dominating the result.

Representative 7-term results:

| Compiler | Native elapsed | Structural elapsed | Native max RSS | Structural max RSS |
| --- | ---: | ---: | ---: | ---: |
| DMD | 0.55 s | 9.58 s | 305560 KiB | 5003680 KiB |
| LDC | 0.64 s | 11.35 s | 405060 KiB | 5815836 KiB |

The structural path also showed strong growth as term count increased, while the
native canonical-type path remained comparatively flat. The benchmark is a
stress probe rather than a prediction of ordinary consumer build cost, but the
direction and magnitude are consistent across both baseline compilers.

**R04.11 decision:** canonicalize dimensions before forming their concrete D
type, then use native type identity for ordinary internal dimension equality
gates. Do not make structural `sameDimension` the default arithmetic path.

Structural protocol detection remains useful as an explicit interoperability,
validation, or adaptation boundary for foreign dimension-like types. Such a
foreign representation should be normalized/adapted into the canonical core
representation once, rather than repeatedly paying structural equality cost
through arithmetic operations.

This preserves both goals:

- open consumer participation at the boundary;
- cheap canonical nominal identity inside quantities-d arithmetic.

### Dimension tag ordering key

The ordering-key probe passes on both baseline compilers. DMD and LDC produced
the same fully qualified tag names for the tested core and consumer tags, for
example:

- `r04_11_dimension_key_probe.LengthTag`
- `r04_11_dimension_key_probe.ConsumerAxisTag`

Using `std.traits.fullyQualifiedName!Tag` as a compile-time **ordering key**
therefore provides an open canonicalization mechanism without a core-owned
`TagRank` registry and without requiring every consumer tag to publish a
manual string key.

Important separation:

- the qualified name is only an ordering device;
- mathematical tag identity remains nominal D type identity;
- two distinct tag types must never become the same mathematical axis merely
  because an ordering key collides.

The explicit-key probe remains useful as evidence that custom keys are
possible, but it is no longer the preferred default API. Requiring manual
`dimensionKey` strings would add public naming policy and collision management
without demonstrated need.

**R04.11 direction:** prefer automatic qualified-name ordering for canonical
term construction, with nominal tag identity as the semantic identity rule.
Keep any explicit ordering-key customization out of the initial public API
unless a concrete consumer case requires it.

Caveat: a qualified name changes when a tag is renamed or moved to another
module. That can change canonical term ordering and mangled type names, but it
does not change mathematical identity within one build. Before production,
ABI / serialized-type-name stability should be treated separately from
mathematical correctness; quantities-d should not promise stable ABI based on
internal template mangling unless explicitly designed for it.

### ResultSpec canonical rescale integration

The result-spec canonical-rescale probe now passes on both baseline compilers.
It closes the R04.11 chain from semantic result selection through canonical
storage:

1. Spec algebra selects a unique semantic ResultSpec.
2. Dimension algebra derives the mathematical result dimension.
3. Unit algebra derives the mathematical result unit and exact rational scale
   from the operands' canonical units.
4. ResultSpec.CanonicalUnit defines the storage unit of the resulting Quantity.
5. CanonicalRescale = MathResultUnit.Scale / ResultSpec.CanonicalUnit.Scale.
6. Rep / exactness gates decide whether a direct operator is total and safe.

Reference case:

- Length canonical unit: metre
- mathematical Length x Length unit: square metre
- Area canonical unit: square metre -> rescale 1
- AreaKm2 canonical unit: square kilometre -> rescale 1/1_000_000

For integral storage, a reduced canonical-rescale denominator other than 1 is
not exact for every representable product value. Therefore a direct integral
operator must not silently produce an integral Quantity in such a ResultSpec.
For example, 3 m * 4 m = 12 m2 = 0.000012 km2, while 1000 m * 1000 m = 1 km2
is exactly representable. This establishes the distinction between a
value-independent direct-operator gate and a value-dependent named exact /
checked path.

**R04.11 direct integral product contract:** a direct Quantity x Quantity
operator may compile only when all of the following hold:

1. semantic gate: exactly one ResultSpec is selected;
2. dimension gate: ResultSpec.Dimension equals the product dimension;
3. unit gate: mathematical result unit and ResultSpec.CanonicalUnit share that
   dimension;
4. product-range gate: a built-in ResultRep contains the complete mathematical
   product range of the operand Reps;
5. canonical-rescale exactness gate: the reduced rescale denominator is 1 for
   integral storage;
6. post-rescale range gate: the integer rescale multiplier still fits the
   ResultRep for every operand pair.

Extended invariant:

> If a direct integral quantities-d product operator compiles, neither overflow
> nor canonical-unit truncation is possible for any value representable by its
> operand Reps.

Fractional canonical rescaling does not make the semantic relation invalid; it
only removes the total direct integral operator. A future explicit exact /
checked product API can still succeed for selected values.

### Exact arithmetic result carrier

The shared exact-arithmetic result carrier probe passes on both baseline
compilers.

The evidence supports sharing only the constructive payload/failure mechanism,
not the semantic failure domain itself:

- product failures: inexact, overflow;
- division failures: inexact, divisionByZero;
- no broad ArithmeticStatus is required.

A generic internal carrier of the form

    ExactArithmeticResult!(T, Failure)

can provide the common state machine:

- exact success carries a payload;
- failure carries an operation-specific Failure enum;
- contradictory public states are not constructible;
- tryValue / tryFailure provide read access;
- default initialization remains a valid failure state when the chosen Failure
  enum gives its zero value the intended default semantics.

Public API names should remain operation-specific where that improves meaning.
For example, ProductResult!T and DivisionResult!T may be aliases or thin
wrappers over the shared internal carrier without forcing their failure enums
into one common status type.

Decision direction: **share mechanics, preserve semantic status domains.**

### Production-readiness assessment after end-to-end Quantity product probe

The production-shaped Quantity product integration probe passes on both DMD
2.111 and LDC 1.41. The research evidence is now sufficient to define a first
production slice, but not to claim the full derived-arithmetic design complete.

#### Ready to promote conceptually

- direct integral Quantity x Quantity only when semantic, dimension, unit,
  representation, exact-rescale, and post-rescale range gates are all total;
- Length x Length -> Area as the first reference semantic relation;
- exact rational derived-unit scale propagation;
- canonical-result-unit rescaling rather than raw reinterpretation;
- value-dependent named exact multiplication for cases where the semantic
  relation is valid but the direct integral operator is not total;
- shared internal constructive exact-arithmetic carrier while preserving
  operation-specific failure domains;
- no broad ArithmeticStatus;
- no exhaustive physics catalogue requirement.

#### Production dependencies still required before the first PR

1. **Canonical open dimension representation in the production core.**
   The research model is proven, including normalization-before-type-formation,
   automatic fullyQualifiedName ordering, native type equality, and consumer
   extension. Production still uses a nominal LengthDimension only.

2. **Generic unit algebra over production ExactRatio.**
   MulUnit, DivUnit, and PowUnit must use overflow-safe/reduction-safe exact
   ratio composition rather than the simplified research arithmetic.

3. **Final ProductResultSpec resolution API.**
   Member ProductWith / reverse hook / explicit relation-set behavior and
   conflict rules must be represented by one normative trait. Two foreign Specs
   require the explicit relation-set escape hatch; silent override is rejected.

4. **Full scaled-product ResultRep integration.**
   The separate exact-range research proves the safety direction, but the
   production operator must use one normative selector for the complete
   expression lhs * rhs * integerRescale. The end-to-end probe intentionally
   admits only rescale == 1 on its direct path.

#### Recommended first production slice

Keep the first production change deliberately narrow:

- introduce canonical open Dimension primitives and algebra;
- introduce generic derived Unit algebra;
- add Area / SquareMetre as the first standard derived quantity;
- add the normative product semantic trait;
- add direct integral Quantity x Quantity for the total rescale==1 reference
  path first;
- add exactMul only after its ResultRep/rescale implementation reuses the same
  normative product pipeline and preserves the established exact/inexact/
  overflow contract;
- retain all non-total cases as compile-time rejection until their named path is
  fully implemented.

This ordering avoids merging a partially duplicated arithmetic pipeline and
keeps the existing invariant intact:

> If a direct integral quantities-d arithmetic operator compiles, overflow and
> semantic/canonical-unit truncation are impossible for every representable
> operand value.

R04.11 itself should remain open until the production slice has passed DMD/LDC
debug and release tests, compile-negative gates, external-consumer tests, and a
final review against the research invariants.
