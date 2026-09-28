# quantities-d-research

Research, experiments, probes, measurements, and supporting evidence for
[quantities-d](https://github.com/alex-1974/quantities-d).

This repository contains development evidence rather than the distributable
library.

Accepted architectural decisions and production code belong in `quantities-d`.
Research here may contain experimental APIs, compiler probes, code-generation
measurements, exhaustive type audits, and rejected designs.

## Relationship to quantities-d

- `quantities-d` is the production and release repository.
- `quantities-d-research` preserves the evidence behind design decisions.
- Production APIs must not depend on this repository.
- Relevant conclusions are promoted back to `quantities-d` as compact ADRs,
  architecture documentation, tests, and production code.

## Generated artifacts

Generated executables, object files, DUB build directories, temporary compiler
output, and bulk result artifacts are not committed unless a small textual
result is intentionally preserved as research evidence.
