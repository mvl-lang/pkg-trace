# Changelog

All notable changes to pkg-trace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.3] - 2026-06-14

### Fixed
- Logfmt span output now uses `YYYY-MM-DD HH:MM:SS SPAN  name fields` prefix, matching `std.log` plain format for consistent interleaved screen output

## [0.3.2] - 2026-06-14

### Fixed
- Avoid move of `end_ts` in `emit_span` `None` branch — recompute timestamp from `end_time` instead of reusing the string, which the Rust backend treats as a move

## [0.3.1] - 2026-06-14

### Added
- `start_time` field in both logfmt and JSON span output — consumers can now compute duration without external clock

## [0.3.0] - 2026-06-14

### Changed
- **BREAKING**: `span_end` and `span_error` now require a `Tracer` as the first argument (was using a global tracer)
- **BREAKING**: `span_set` now returns `TraceContext` (pure function) instead of `Unit ! Trace` (was imperative)
- Complete rewrite: Pure MVL implementation. All spans emitted as structured logs to a configurable `Fd` (default stderr)
- `Trace` effect now subsumes `Clock + CryptoRandom + Console` (previously had no effect dependencies declared)

### Removed
- **BREAKING**: `pub builtin fn` declarations — pkg-trace is now pure MVL; no extern FFI calls
- `traced[T, E]` wrapper (generic effects not supported in regular functions)

### Added
- `Tracer` struct for output configuration: format (Logfmt/Json) and fd (stderr, file, pipe)
- `default_tracer()` and `file_tracer(fd, format)` constructors
- `SpanFormat` enum: `Logfmt` and `Json` output formats
- Pure MVL span emission: logfmt and JSON-compatible output
- W3C Trace Context (traceparent header) parsing and formatting
- Baggage support for context propagation across service boundaries

## [0.2.1] - 2026-06-14

### Fixed
- Declare `pub effect Trace > Clock + CryptoRandom` in `src/trace.mvl` — the effect was used in all `builtin fn` signatures but never declared, causing a compiler error on import

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
