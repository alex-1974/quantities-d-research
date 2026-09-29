# R04.14 Probe 8 — fixed-width checked rescale kernel

This probe implements the Probe-7 state semantics without BigInt in the
candidate kernel.

Algorithm:

1. separate sign and unsigned magnitudes;
2. cross-cancel the denominator against lhs magnitude, rhs magnitude, and the
   scale numerator;
3. if a denominator remains, return `inexact`;
4. derive the final signed-result magnitude limit;
5. multiply the remaining factors only after division-based bound checks;
6. return `overflow` only if the exact integral final magnitude cannot fit;
7. otherwise construct the exact `long` result, including `long.min`.

The candidate kernel is `@safe pure nothrow @nogc` and CTFE-capable.
A research-only BigInt oracle checks a systematic Cartesian boundary set.

Run with DMD and LDC.
