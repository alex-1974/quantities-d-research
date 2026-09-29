# R04.14 Probe 7 — checked product rescale state model

This probe studies the interaction between value-dependent Class-O overflow
and exact canonical rescaling.

For an integral canonical product

    (lhs * rhs * numerator) / denominator

the semantic runtime outcomes are tested as three disjoint states:

- exact
- inexact
- overflow

The exact BigInt oracle deliberately evaluates the complete mathematical
expression before classification. This prevents an implementation artifact
such as an overflowing intermediate product from being mistaken for result
overflow.

Classification order is mathematical, not implementation order:

1. determine whether the rational result is integral;
2. if not integral -> inexact;
3. if integral, determine whether the exact integer fits ResultRep;
4. if not -> overflow;
5. otherwise -> exact.

This distinction matters because a large intermediate numerator may exceed the
ResultRep while exact division later produces a representable result.

The probe is research-only and uses BigInt as an oracle.

Run:

```sh
dub run --compiler=dmd --force
dub run --compiler=ldc2 --force
```
