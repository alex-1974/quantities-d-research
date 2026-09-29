# R04.14 Probe 4 — adversarial exact oracle

This probe audits the O64 predicates from Probe 3 against independent exact
`std.bigint.BigInt` arithmetic.

The production candidate remains fixed-width and allocation-free. `BigInt`
exists only in this research executable as an oracle.

The test set concentrates on:

- both signed endpoints and adjacent values;
- zero and small signed values;
- half-range values;
- the `long.max` / unsigned transition;
- `ulong.max` and adjacent values.

For every Cartesian pair it checks:

1. whether the predicate's success/overflow classification matches exact
   mathematical representability in the target Rep;
2. if successful, whether the returned fixed-width value equals the exact
   mathematical result.

Run with both baseline compilers:

```sh
dub run --compiler=dmd --force
dub run --compiler=ldc2 --force
```
