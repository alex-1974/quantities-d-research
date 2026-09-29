# R04.14 Probe 6 — OM result-domain audit

Probe 6 studies mixed-domain (OM) Class-O arithmetic independently of API
design.

The question is not how to detect overflow. It is what a successful value would
have to mean when the mathematical result set crosses the built-in
`long`/`ulong` boundary.

For representative OM families, exact `BigInt` endpoint enumeration derives
the complete mathematical result range and classifies whether it fits:

- `long`;
- `ulong`;
- neither built-in 64-bit domain.

It also reports whether the complete range itself requires more than 64 value
bits/sign information.

Representative families include:

- signed-small with `ulong` for addition and multiplication;
- `long` with `ulong`;
- `ulong - ulong`;
- both ordered signed/unsigned subtraction directions.

This is research-only. `BigInt` is an exact oracle, not a production
representation proposal.

Run:

```sh
dub run --compiler=dmd --force
dub run --compiler=ldc2 --force
```
