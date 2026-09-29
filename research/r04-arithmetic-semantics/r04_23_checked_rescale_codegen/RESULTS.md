# R04.23 Results

## Semantic closure

### 23h

Signed and zero normalized-ratio kernel:

| Compiler | Result |
|---|---|
| DMD 2.111 | PASS |
| DMD 2.113 | PASS |
| LDC 1.41 | PASS |

Explicitly exercised:

- zero numerator,
- negative scale,
- `long.min` numerator,
- cancellation,
- inexact results,
- final overflow.

### 23i BigInt oracle

Independent mathematical comparisons per compiler:

    10,004

Results:

| Compiler | Comparisons | Result |
|---|---:|---|
| DMD 2.111 | 10,004 | PASS |
| DMD 2.113 | 10,004 | PASS |
| LDC 1.41 | 10,004 | PASS |

No discrepancy was observed between the BigInt oracle and either final
candidate.

## R04.23g performance conclusion

Candidate C uses a portable division-bound overflow proof.

Candidate D uses `core.checkedint.mulu`.

### DMD 2.111

The result is operand dependent.

Candidate D is faster for several small/cancellation workloads, while
candidate C is faster for important full-width and overflow workloads.

This does not support a stable DMD-2.111-specific specialization.

### DMD 2.113

Candidate C is generally preferable.

Candidate D retains a modest advantage in the 1/2 cancellation workload but
loses in the common denominator-one cases and especially when multiple helper
calls are required.

### LDC 1.41

Candidate D wins every measured workload, often by a large margin.

Representative final-kernel results are approximately:

| Workload | C ns/op | D ns/op |
|---|---:|---:|
| 1/1 exact-small | 9-10 | 2-3 |
| 1/1 exact-wide | 9-10 | 2-3 |
| 1/2 cancellation-exact | 26 | 19 |
| 2/1 exact | 8-9 | 3 |
| 7/15 cancellation-exact | 20-21 | 16 |
| 1/1 overflow | 9 | 2 |

This is consistent with LDC lowering checked multiplication to native
overflow-aware machine operations.

## Bounds-check control

The final R04.23g benchmark was rebuilt and rerun with bounds checking both
off and on.

All six builds succeeded:

- DMD 2.111 boundscheck off
- DMD 2.111 boundscheck on
- DMD 2.113 boundscheck off
- DMD 2.113 boundscheck on
- LDC 1.41 boundscheck off
- LDC 1.41 boundscheck on

The on/off measurements preserve the same qualitative result:

- DMD 2.111 remains mixed.
- DMD 2.113 generally favors C.
- LDC strongly favors D in every workload.

Observed differences between boundscheck configurations are small relative to
the backend effects and do not change the implementation decision.

## Decision

Use one semantic kernel with a centralized checked-multiplication backend:

    version (LDC)
        candidate D
    else
        candidate C

Do not introduce a DMD-version matrix.

Do not expose the backend distinction through the public API.
