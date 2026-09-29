# R04.14 Probe 3 — O64 overflow predicates

This probe implements value-dependent checked arithmetic only for the O64
subset identified by Probe 2.

It deliberately does not use compiler overflow intrinsics or
`core.checkedint` as the semantic basis. Every predicate proves
representability before the potentially overflowing operation is executed.

Covered prototype domains:

- signed-result addition -> `long`;
- signed-result subtraction -> `long`;
- unsigned-result addition -> `ulong`;
- signed-result multiplication -> `long`;
- unsigned-result multiplication -> `ulong`.

Mixed-domain OM cases remain excluded.

The probe requires:

- boundary success/failure immediately around min/max;
- mixed-width O64 examples;
- CTFE;
- `@safe pure nothrow @nogc`;
- identical DMD/LDC behavior.

Run:

```sh
dub run --compiler=dmd --force
dub run --compiler=ldc2 --force
```
