# R04.14 Probe 9 — result-carrier comparison

This probe compares result-carrier shapes for checked Class-O arithmetic
against the existing M3 contracts.

Existing production semantics:

- `ProductResultValue!T`: value or `ProductFailure.inexact`;
- `DivisionResult!T`: `exact | inexact | divisionByZero`.

R04.14 introduces two distinct checked surfaces:

1. unscaled checked O64 arithmetic: value or `overflow`;
2. rescaled checked product: `exact | inexact | overflow`.

The probe rejects a universal `ArithmeticStatus` hypothesis as too broad:
operations should not expose states that are semantically impossible for them.

Candidate policy:

- operation-specific public failure/status enums;
- a structurally reusable private/internal value-or-failure carrier where the
  state space is binary;
- a product-specific public status/result carrier for rescaled checked product.

This keeps semantic vocabulary narrow while allowing implementation reuse.

The probe checks CTFE, `@safe pure nothrow @nogc`, default-state behavior,
and that unrelated states cannot be expressed through the public type.

No production API is changed.
