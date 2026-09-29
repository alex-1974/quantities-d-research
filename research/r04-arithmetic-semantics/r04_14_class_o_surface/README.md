# R04.14 Probe 1 — Class-O surface

This probe copies the current production Class-W shape algorithm into an
isolated research executable and classifies all ordered pairs of D's eight
built-in integral Reps for addition, subtraction, and multiplication.

It does not implement checked arithmetic.

## Run

```sh
dub run --compiler=dmd
dub run --compiler=ldc2
```

The two compilers must print identical counts and matrices.

Rep order in every row/column:

`byte ubyte short ushort int uint long ulong`

`W` means the complete mathematical operation range fits a built-in Rep.
`O` means no built-in Rep can contain the complete range and the pair is
therefore Class O under the current production rule.
