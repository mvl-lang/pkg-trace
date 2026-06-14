# Spec 001: Trace Context

> Distributed tracing with spans and W3C Trace Context propagation.
> Issues: #1 (sampling), #2 (exporters), #3 (IFC guard), #4 (W3C flags), #5 (tracestate)

## Overview

`pkg.trace` is the tracing component of MVL's observability triangle (logs, metrics, trace).
It provides span lifecycle management, W3C Trace Context propagation, and baggage passing.

Distributed traces link spans across service boundaries using the W3C `traceparent` header,
making it possible to follow a request from entry point through actors, DB calls, and
downstream services in a single trace view.

## Architecture

```
┌──────────────────────────────────────────┐
│  MVL Application                         │
│  (handle_request, db calls, actors)      │
├──────────────────────────────────────────┤
│  pkg.trace                               │
│  trace_start / span_start / span_end     │
│  span_set / traced / baggage_set         │
│  parse_traceparent / format_traceparent  │
├──────────────────────────────────────────┤
│  std.time  (Timestamp, now)              │
│  std.crypto (uuid_v4)                    │
├──────────────────────────────────────────┤
│  Exporter (OTLP / Jaeger / Zipkin) — #2  │
└──────────────────────────────────────────┘
```

---

### Requirement 1: Trace lifecycle [MUST]

A trace starts with `trace_start` and ends when all spans in the trace have been ended.
Each span records a name, timing, attributes, and status.

**Implementation:** `src/trace.mvl::trace_start`, `span_start`, `span_end`, `span_error`

#### Scenario: Root span lifecycle

- GIVEN an HTTP handler
- WHEN `trace_start("http.request")` is called on entry
- THEN a `TraceContext` is returned with a fresh `trace_id` and `span_id`

#### Scenario: Child span lifecycle

- GIVEN an active `TraceContext ctx`
- WHEN `span_start("db.query", ctx)` is called
- THEN the returned context shares `ctx.trace_id` and has `parent_span_id = Some(ctx.span_id)`

---

### Requirement 2: Span attributes [MUST]

Spans carry arbitrary key-value string attributes.
Attributes MUST NOT contain PII — see #3 for the planned `Public[String]` guard.

Common attribute keys follow OpenTelemetry semantic conventions:
`http.method`, `http.path`, `db.statement`, `user.id`, `error.message`.

**Implementation:** `src/trace.mvl::span_set`

#### Scenario: HTTP span attributes

- GIVEN an HTTP request span
- WHEN `span_set(ctx, "http.method", "GET")` and `span_set(ctx, "http.path", "/users")` are called
- THEN the completed span records both attributes

---

### Requirement 3: W3C traceparent propagation [MUST]

Incoming `traceparent` headers are parsed to continue a distributed trace.
Outgoing requests include a `traceparent` header to propagate context downstream.

The header format is `00-{trace_id}-{parent_id}-{flags}` per W3C Trace Context Level 1.

**Implementation:** `src/trace.mvl::parse_traceparent`, `format_traceparent`

#### Scenario: Incoming traceparent

- GIVEN an HTTP request with header `traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01`
- WHEN `parse_traceparent(header)` is called
- THEN `Some(TraceContext { trace_id: "0af7651916cd43dd8448eb211c80319c", span_id: "b7ad6b7169203331", ... })` is returned

#### Scenario: Invalid traceparent rejected

- GIVEN a header with a non-hex trace_id or unsupported version
- WHEN `parse_traceparent(header)` is called
- THEN `None` is returned

#### Scenario: Outgoing traceparent

- GIVEN `ctx` with `trace_id = "abc..."` and `span_id = "def..."`
- WHEN `format_traceparent(ctx)` is called
- THEN `"00-abc...-def...-01"` is returned

---

### Requirement 4: Remote parent context semantics [MUST]

`parse_traceparent` returns a context representing the **remote parent span**.
The returned context MUST be passed to `span_start` to create a local child span.
It MUST NOT be passed to `span_end` or `span_error` (those remote spans are not owned locally).

**Implementation:** `src/trace.mvl::parse_traceparent`

#### Scenario: Correct distributed trace chain

- GIVEN remote context `r` from `parse_traceparent`
- WHEN `span_start("handler", r)` is called
- THEN `local_span.parent_span_id = Some(r.span_id)` — chain is unbroken

---

### Requirement 5: Baggage propagation [MUST]

Baggage carries business context across service boundaries (e.g. `tenant_id`, `user_tier`).
Baggage is immutable per context; `baggage_set` returns a new context.
Callers MUST use baggage sparingly — it travels with every request.

**Implementation:** `src/trace.mvl::baggage_set`, `baggage_get`

#### Scenario: Baggage round-trip

- GIVEN `ctx` with no baggage
- WHEN `let ctx2 = baggage_set(ctx, "tenant", "acme")`
- THEN `baggage_get(ctx2, "tenant") == Some("acme")`
- AND `baggage_get(ctx, "tenant") == None` (original unchanged)

---

### Requirement 6: Sampling [SHOULD] — #1

A configurable sampler controls what fraction of traces are recorded.
Default: always sample (current behaviour, equivalent to `Sampler::Always`).
Production deployments SHOULD use `Sampler::Rate { rate: 0.1 }` or lower.

Linked to W3C flag propagation (#4): when a trace is not sampled, outgoing
`traceparent` headers MUST carry flags byte `00`.

**Implementation:** pending — tracked in [#1](https://github.com/mvl-lang/pkg-trace/issues/1)

---

### Requirement 7: Exporter [SHOULD] — #2

Spans are exported to a backend for storage and querying.
Supported formats: OTLP (preferred), Jaeger, Zipkin.
Without an exporter, spans are recorded in memory only and discarded on process exit.

**Implementation:** pending — tracked in [#2](https://github.com/mvl-lang/pkg-trace/issues/2)

---

### Requirement 8: IFC guard on span attributes [SHOULD] — #3

`span_set` attribute values SHOULD require `Public[String]` to prevent PII from
leaking into traces at compile time, using MVL's information-flow control system.

**Implementation:** pending — tracked in [#3](https://github.com/mvl-lang/pkg-trace/issues/3)

---

### Requirement 9: W3C sampling flags [SHOULD] — #4

The flags byte in `traceparent` SHOULD be parsed and honoured:
- Bit 0 (`0x01`): sampled. If clear on an incoming request, respect the upstream
  sampling decision and propagate `00` on outgoing requests.

**Implementation:** pending — tracked in [#4](https://github.com/mvl-lang/pkg-trace/issues/4)

---

### Requirement 10: tracestate support [MAY] — #5

The W3C `tracestate` header carries vendor-specific context (Datadog `dd=...`,
AWS X-Ray, etc.). `parse_tracestate` and `format_tracestate` MAY be added to
avoid losing vendor context at MVL service boundaries.

**Implementation:** pending — tracked in [#5](https://github.com/mvl-lang/pkg-trace/issues/5)

---

## File Inventory

| File | Role |
|------|------|
| `src/trace.mvl` | Types, span lifecycle, baggage, W3C propagation |
