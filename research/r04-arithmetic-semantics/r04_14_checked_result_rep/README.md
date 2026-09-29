# R04.14 Probe 2 — checked ResultRep hypotheses

## Purpose

Determine whether Class-O checked arithmetic needs a widened common operand Rep,
or whether the result domain can be selected independently while overflow is
tested against the original operand values.

Probe 1 established that Class O occurs exactly when at least one operand is
`long` or `ulong`.

## Critical distinction

A checked operation does not need a type that contains the *complete
mathematical operation range*. If such a built-in type existed, the pair would
already be Class W.

It needs:

1. a declared ResultRep defining which mathematical results count as success;
2. an overflow predicate evaluated without lossy operand conversion;
3. construction of ResultRep only after the predicate proves the exact result
   is representable.

Therefore these are separate questions:

- **CommonOperandRep:** can one built-in Rep losslessly hold every value of both
  operands?
- **CheckedResultRep:** which built-in Rep should define the success domain?

For `long/ulong`, CommonOperandRep is necessarily void. This alone must not
prove that checked arithmetic is impossible.

## Candidate ResultRep rule

Test this minimal rule first:

- if either operand is `ulong` and no negative mathematical result is possible
  for the operation/domain, candidate `ulong`;
- otherwise candidate `long`.

This is intentionally only a hypothesis. In particular:

- `long + ulong` can produce negative values and values above `long.max`;
  neither built-in 64-bit Rep contains all successful mathematical results one
  might wish to preserve;
- `ulong - long` and `long - ulong` are asymmetric;
- mixed signed/unsigned multiplication can be negative or exceed `long.max`.

Probe 2 must expose these ambiguities rather than hide them behind D promotion.

## Questions to answer

1. Should success mean "result fits one deterministic 64-bit ResultRep"?
2. If yes, which ResultRep is least surprising for mixed signed/unsigned pairs?
3. Would choosing `long` reject mathematically valid positive results in
   `long.max+1 .. ulong.max`?
4. Would choosing `ulong` reject mathematically valid negative results?
5. Is such rejection correctly called `overflow`, or does it reveal that some
   mixed pairs need a different API/result model?
6. Can operand-domain checks be performed directly on original signedness
   without a common conversion Rep?

## Required boundary examples

### long + long

Candidate ResultRep: long.

- long.max + 0 -> success
- long.max + 1 -> overflow
- long.min + 0 -> success
- long.min + (-1) -> overflow

### ulong + ulong

Candidate ResultRep: ulong.

- ulong.max + 0 -> success
- ulong.max + 1 -> overflow

### long + uint / uint + long

Candidate ResultRep: long.

- long.max + 0 -> success
- long.max + 1u -> overflow
- -1L + uint.max -> success

### ulong + uint / uint + ulong

Candidate ResultRep: ulong.

- ulong.max + 0 -> success
- ulong.max + 1u -> overflow

### long + ulong / ulong + long

No candidate is accepted a priori.

Demonstrate both representable regions:

- -1L + 0UL -> negative result requires signed storage
- 0L + ulong.max -> positive result requires unsigned 64-bit storage

A single built-in 64-bit ResultRep cannot preserve both.

### subtraction

Repeat the analysis in operand order. In particular:

- ulong - ulong can be negative, so `ulong` is not an adequate universal
  checked ResultRep if negative successful results are intended;
- long - ulong and ulong - long span both sides of the 64-bit signed/unsigned
  boundary.

### multiplication

- long * long naturally targets checked long;
- ulong * ulong naturally targets checked ulong;
- long * unsigned can be negative and can exceed long.max;
- signed/unsigned 64-bit mixtures therefore require explicit policy evidence.

## Expected outcome

Probe 2 may split Class O into two categories:

- **O64:** a natural 64-bit ResultRep exists and checked overflow is sufficient;
- **OM:** mixed-domain cases where no single built-in Rep preserves the natural
  success set.

If OM exists, do not force it into `value | overflow` merely for API symmetry.
