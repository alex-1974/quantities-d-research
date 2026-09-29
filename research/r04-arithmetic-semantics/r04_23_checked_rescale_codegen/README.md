# R04.23 — Checked canonical-rescale codegen and performance

## Purpose

R04.23 investigates the integral Class-O64 checked canonical-rescale kernel
needed by R04.14.

The mathematical operation is:

    (lhs * rhs * Numerator) / Denominator

where `Numerator/Denominator` is the normalized `ExactRatio` supplied by
`ProductCanonicalRescale`.

The required observable result states are:

- exact
- inexact
- overflow

Overflow refers to the final exact mathematical result, not to an avoidable
intermediate product.

## Production ratio contract

The production unit model permits:

- positive scale numerators,
- negative scale numerators,
- zero scale numerators,
- a positive normalized denominator.

Therefore the final kernel must support signed and zero scale numerators.

For a normalized nonzero ratio:

    gcd(abs(Numerator), Denominator) == 1

After cancelling the denominator against the two operand magnitudes, any
remaining denominator cannot be cancelled against the scale numerator.
A remaining denominator therefore means that the integral result is inexact.

A zero numerator is a compile-time special case and returns exact zero before
any multiplication is attempted.

## Probe evolution

### Initial runtime-scale kernel — `app.d`

Established the basic cross-cancellation algorithm and showed that treating
the scale numerator and denominator as runtime values leaves unnecessary
dynamic division and GCD work.

### Static scale — `static_scale.d`

Moved the scale ratio into template arguments.

This alone was insufficient for DMD to eliminate all general-purpose
cancellation machinery.

### 23c — `static_scale_23c.d`

Used explicit compile-time structure:

- special handling for `Denominator == 1`,
- denominator cancellation only where required,
- removed the redundant `gcd(Numerator, denominator)` step using the
  normalized `ExactRatio` invariant.

This substantially reduced DMD code for denominator-one cases.

### 23d — `static_scale_23d.d`

Replaced the final division-bound multiplication proof with
`core.checkedint.mulu`.

Code generation showed:

- LDC lowers this efficiently to native overflow-aware multiplication,
- DMD 2.111 uses a portable implementation that may contain division,
- newer DMD uses a runtime helper call for the relevant 64-bit multiply.

### 23e — `benchmark_23e.d`

Benchmarked the 23c and 23d approaches.

This exposed structurally unnecessary checked multiplications inherited from
the general product loop.

### 23f — `static_scale_23f.d`

Removed those unnecessary multiply-by-one operations and specialized the
compile-time numerator structure.

This is the structural basis for the final candidates.

The probe also exposed a missing production-contract case: a zero scale
numerator must be handled before multiplication.

### 23g — `benchmark_23g.d`

Benchmarked the structurally specialized C and D candidates.

Candidate C:
portable division-bound checked multiplication.

Candidate D:
`core.checkedint.mulu`.

The results established a backend distinction rather than a compiler-version
matrix:

- LDC strongly favors candidate D.
- DMD results are mixed and operand-distribution dependent.
- DMD 2.113 generally favors candidate C.
- DMD 2.111 does not provide a stable reason for a version-specific policy.

### 23h — `static_scale_23h.d`

Completed the production semantics:

- zero numerator,
- negative numerator,
- `long.min`,
- signed result limits,
- cancellation before multiplication,
- exact/inexact/overflow states.

The result sign is:

    sign(lhs) XOR sign(rhs) XOR sign(Numerator)

Magnitude arithmetic is unsigned and handles `long.min` without signed
absolute-value overflow.

### 23i — `bigint_oracle_23i.d`

Validated both final candidates against an independent `std.bigint.BigInt`
mathematical oracle.

The oracle deliberately does not share:

- magnitude arithmetic,
- GCD cancellation,
- checked multiplication,
- candidate overflow logic.

Each tested compiler completed 10,004 oracle comparisons with no discrepancy:

- DMD 2.111: PASS
- DMD 2.113: PASS
- LDC 1.41: PASS

The tested ratios include zero, positive and negative scales, cancellation,
large numerators, `long.min`, `long.max`, and large denominators.

## Final implementation direction

The research supports a centralized backend specialization:

    version (LDC)
        use core.checkedint.mulu
    else
        use portable division-bound checked multiplication

This is a backend capability distinction, not a DMD-version-specific policy.

Both paths implement the same arithmetic semantics.

The specialization should remain local to the checked multiplication
primitive used by the canonical-rescale kernel.

## Non-goals and rejected directions

R04.23 does not justify:

- a public API representation chosen for compiler ABI/codegen behavior,
- DMD-version-specific public behavior,
- custom inline assembly,
- split-32 multiplication,
- ImportC overflow builtins,
- software 128-bit arithmetic for O64,
- changing `exactMul` into an overflow-checking operation.

Those alternatives were investigated earlier in R04.14 and did not provide a
better portable design.

## Performance methodology

The performance probes use:

- 20,000,000 iterations,
- five runs per workload,
- 1,024-element data sets,
- optimized release builds.

R04.23g measured the final structural candidates with bounds checking disabled.

A final control repeated the same benchmark with bounds checking both enabled
and disabled. The control did not change the backend conclusion:

- DMD remains mixed and supports the portable candidate as the stable default.
- LDC continues to strongly favor `core.checkedint.mulu`.
- no systematic bounds-check penalty changes the implementation choice.

## Conclusion

The checked canonical-rescale mechanism is semantically and experimentally
closed for the R04.14 research scope.

The production candidate is:

1. exploit normalized `ExactRatio` invariants at compile time,
2. return exact zero immediately for a zero numerator,
3. compute sign separately,
4. convert operands and numerator to unsigned magnitudes,
5. cancel the denominator against operand magnitudes,
6. return `inexact` if a denominator remains,
7. perform checked magnitude multiplication,
8. enforce the final signed result magnitude,
9. reconstruct the signed result, including exact `long.min`.

Backend checked multiplication:

- LDC: `core.checkedint.mulu`
- portable/default including DMD: division-bound proof

Further microbenchmark exploration is not required before production
integration.
