# R04.14 Probe 5 — Quantity-shaped checked API

This probe tests the API shape of named checked Class-O arithmetic against the
current M3 architecture.

Research names:

- `checkedAdd`
- `checkedSub`
- `checkedMul`

These names are intentionally distinct from `exactMul`. In current production
`exactMul` expresses exact canonical-unit rescaling; overloading that name
with value-dependent overflow semantics would conflate independent concerns.

The prototype preserves:

1. semantic resolution before representation policy;
2. direct operators as Class-W only;
3. O64 as `value | overflow`;
4. OM as compile-time unavailable;
5. product semantic relation resolution before O64 checking.

For Q x Q multiplication this first probe admits only canonical rescale 1/1.
Combining `ProductFailure.inexact` with checked overflow is deferred so that
the two runtime failure dimensions are not silently collapsed.

The executable is self-contained but mirrors current production concepts:
Quantity, additive/scalable semantic gates, ProductResultSpec, and named result
carrier.

Run:

```sh
dub run --compiler=dmd --force
dub run --compiler=ldc2 --force
```
