# pkg-trace

MVL distributed tracing package — spans, trace context, and W3C propagation.

## Installation

Add to your `mvl.toml`:

```toml
[dependencies]
trace = { git = "https://github.com/mvl-lang/pkg-trace" }
```

## Usage

```mvl
use pkg.trace.{trace_start, span_start, span_end, span_set, TraceContext}

fn handle_request(req: Request) -> Response ! Net + DB + Trace {
    let ctx = trace_start("handle_request");
    span_set(ctx, "http.method", req.method);
    span_set(ctx, "http.path", req.path);
    
    let user = get_user(ctx, req.user_id)?;
    let response = process(ctx, user, req)?;
    
    span_end(ctx);
    response
}

fn get_user(parent: TraceContext, id: Int) -> Result[User, Error] ! DB + Trace {
    let ctx = span_start("db.get_user", parent);
    span_set(ctx, "user.id", id.to_string());
    
    let result = db_query("SELECT * FROM users WHERE id = ?", [id]);
    
    span_end(ctx);
    result
}
```

## Features

- **Trace context**: `trace_id`, `span_id`, `parent_span_id`
- **Effect tracking**: `! Trace` in function signatures
- **W3C Trace Context**: HTTP header propagation
- **Baggage**: Propagate business context across services
- **std.log integration**: Automatic `trace_id` in log output

## Export Formats

- OTLP (OpenTelemetry)
- Jaeger
- Zipkin

## Core Types

| Type | Description |
|------|-------------|
| `TraceContext` | Propagated trace/span IDs + baggage |
| `Span` | Single unit of work with timing |
| `SpanStatus` | Ok or Error with message |

## Related

- [#807](https://github.com/LAB271/mvl_language/issues/807) — Original design ticket
- [pkg-metrics](https://github.com/mvl-lang/pkg-metrics) — Metrics
- [pkg-health](https://github.com/mvl-lang/pkg-health) — Health checks
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)

## License

Apache-2.0
