# ADR-0001: Span/Baggage Model and the Effect Trace

**Status:** Accepted
**Date:** 2026-06-18
**Context:** pkg-trace must provide distributed tracing that is composable, safe, and pure-MVL. The core design question is: what are the data types, effect boundary, and ownership model for span lifecycle?

## Decision

### Span lifecycle is purely functional; emission is effectful

`TraceContext` is an immutable struct threaded through the call graph as a value. Mutation helpers (`span_set`, `baggage_set`) take a context by value and return a new context — no shared state, no global variables.

Only two operations cross the effect boundary into `! Trace`:
- `trace_start` / `span_start` — call `uuid_v4()` (CryptoRandom) and `now()` (Clock)
- `span_end` / `span_error` — call `write(fd, ...)` (Console)

All formatting and serialisation helpers (`emit_logfmt`, `emit_json`, `format_attrs_*`, `json_esc`, `opt_str`) are pure `total fn` with no effects.

### Effect Trace subsumes Clock + CryptoRandom + Console

```mvl
pub effect Trace > Clock + CryptoRandom + Console
```

Callers declare `! Trace` and get all three sub-effects automatically. This keeps call sites clean and groups the three sub-effects under a single, meaningful name for distributed tracing.

Consequence: any `! Trace` function can be used from a handler that already declares `! Trace` without listing the sub-effects separately.

### Tracer is plain-old-data

`Tracer { format: SpanFormat, fd: Fd }` is a val-shareable struct. There is no global or thread-local tracer. Callers construct a tracer once (e.g. at startup using `default_tracer()` or `file_tracer(fd, format)`) and pass it to `span_end` / `span_error`. This makes tracer configuration explicit and testable.

### Remote-parent contexts are value-only

`parse_traceparent` returns a `TraceContext` with `start_time: None`. This signals that the context is a remote parent — it is not owned locally and must not be ended with `span_end` or `span_error`. Those functions are no-ops when `start_time` is `None`, providing safety without a separate type.

The returned context is passed to `span_start` to create a locally-owned child span, which correctly links `parent_span_id` to the remote span.

### Baggage travels with the context

`baggage: Map[String, String]` is part of `TraceContext` and is copied to every child span created via `span_start`. This propagates baggage across service boundaries automatically. Callers are advised to use baggage sparingly (it inflates every context copy).

## Consequences

- No global state — all functions are either `total fn` (pure) or `! Trace` (explicit effect).
- `TraceContext` values can be stored, cloned, and inspected without side effects.
- `make assurance` must report 0 implicit-total (`total*`) functions — see ADR-0002.
- Adding exporters (OTLP, Jaeger) — spec 002, issue #2 — will add a new `! Export` effect; `Trace` may be widened to subsume it.
- IFC guard on `span_set` attributes (issue #3) will require `value: Public[String]` when the MVL IFC system lands.

## Connected to

- Spec 001: `src/trace.mvl` — full implementation
- ADR-0002: Explicit `total fn` annotation policy
- Issue #1: Sampling — will add `Sampler` to `Tracer`
- Issue #2: Exporters — will introduce `! Export` effect
- Issue #3: IFC guard on span attributes
