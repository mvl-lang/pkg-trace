# ADR-0002: Explicit `total fn` Annotation Policy

**Status:** Accepted
**Date:** 2026-06-18
**Context:** MVL infers totality for functions that have no unbounded loops and no calls to `partial fn`. These show up as `total*` (implicit) in `mvl assurance`. The question is: should pkg-trace rely on inference or annotate explicitly?

## Decision

**All functions that are total must carry the explicit `total fn` keyword.** No implicit totality (`total*`) is permitted in source files.

Rationale:
- `mvl assurance` reports `N total fn (N explicit, 0 implicit)` — zero implicit is the target state.
- Explicit annotation is a contract: the author claims termination and exhaustiveness, and the checker verifies it. Implicit totality is a silent default that can be broken by adding a call to a `partial fn` without realising the impact.
- `total fn` on a function that calls `partial fn` is a compile error — this is the intended safety net.
- `partial fn` is already explicit; totality should be equally explicit.

## Application

| Function kind | Keyword |
|---|---|
| Pure constructors (`default_tracer`, `file_tracer`) | `total fn` |
| Exhaustive enum match (`format_is_json`, `opt_str`) | `total fn` |
| For-loops over bounded collections (`is_hex_string`, `format_attrs_*`) | `total fn` |
| Sequential string operations (`json_esc`, `emit_logfmt`, `emit_json`) | `total fn` |
| Functional updates (`span_set`, `baggage_set`) | `total fn` |
| Field accessor (`baggage_get`, `format_traceparent`) | `total fn` |
| Calls `uuid_v4()` or `now()` (CryptoRandom/Clock effects) | `fn` with `! Trace` |
| Calls `write(fd, ...)` (Console effect) | `fn` with `! Trace` or `! Console` |

Effect annotations are orthogonal to totality: `pub total fn format_traceparent(ctx: val TraceContext) -> String` is valid (pure, total, no effects).

## What `partial fn` legitimately covers in pkg-trace

- `trace_start`, `span_start` — call `uuid_v4()` and `now()`, which are effectful (not partial in the termination sense, but they cross the effect boundary, so they carry `! Trace` rather than `total fn`)
- `span_end`, `span_error` — call `emit_span` which calls `write`, crossing the Console effect boundary
- `emit_span` — calls `write(fd, line)` (Console effect)
- `parse_traceparent` — uses `return None` early-exit; contains no unbounded loops but is not `total fn` because `empty_string_map()` performs ref mutation (see below)

Note: `empty_string_map` uses a `ref` sentinel workaround for the MVL empty-map literal gap. It is marked `total fn` because the mutation is bounded (one insert, one remove) and purely local — no observable side effects escape the function.

## Consequences

- `make assurance` will report `0 implicit total` — use this as the gate.
- Any new function added without a totality keyword will appear as `total*` and fail the policy check.
- Reviewers should reject PRs that introduce implicit totality.
- When MVL adds a native empty-map literal (e.g. `Map::new()`), `empty_string_map` can be inlined at its three call sites and removed.

## Connected to

- MVL Req 3 (Totality): `mvl assurance` REQ3 verifies this
- MVL Req 8 (Termination): `total fn` functions must have provable termination
- ADR-0001: Span/baggage model — explains which functions carry `! Trace` vs `total fn`
- Spec 001: `src/trace.mvl` — all `total fn` annotations live here
