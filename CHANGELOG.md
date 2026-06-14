# Changelog

All notable changes to pkg-trace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-06-14

### Fixed
- `parse_traceparent`: reject unsupported traceparent versions (only `00` accepted)
- `parse_traceparent`: validate that `trace_id` and `parent_id` are lowercase hex digits
- `parse_traceparent`: clarify that the returned context is the **remote parent** — pass to `span_start`, not `span_end`
- `parse_traceparent`: rename local `span_id` variable to `parent_id` to match W3C terminology
- `format_traceparent`: add missing closing `}` (syntax error)
- `parse_traceparent`: use `Map::new()` for empty baggage (was `{}`, an empty block in MVL)

### Added
- `.openspec/specs/001-trace-context/spec.md` — formal specification
- `CONTRIBUTING.md` — contribution guide
- `CHANGELOG.md` — this file
- `LICENSE` — Apache 2.0

## [0.1.0] - 2026-06-13

### Added
- Initial release — distributed tracing for MVL
- `TraceContext`, `Span`, `SpanStatus` types
- `trace_start`, `span_start`, `span_end`, `span_error`, `span_set` builtins
- `traced[T, E]` convenience wrapper
- `baggage_set`, `baggage_get` for context propagation
- `parse_traceparent`, `format_traceparent` for W3C Trace Context (RFC 7230 / W3C TR trace-context)
- `! Trace` effect
