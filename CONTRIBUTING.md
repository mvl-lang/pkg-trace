# Contributing to pkg-trace

## Getting Started

1. Fork this repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run the type checker: `mvl check src/`
5. Commit with a conventional message: `git commit -m "feat: add ..."`
6. Push and open a pull request

## Development Setup

You need the [MVL compiler](https://github.com/LAB271/mvl_language) installed:

```bash
git clone https://github.com/LAB271/mvl_language.git
cd mvl_language
cargo build
export PATH="$PWD/target/debug:$PATH"
```

## Code Style

- All public functions must have doc comments (`///`)
- All functions must declare their effects (`! Trace` for span operations)
- Span attribute values should not accept PII — see [#3](https://github.com/mvl-lang/pkg-trace/issues/3) for the planned `Public[String]` guard
- W3C Trace Context conventions must be maintained (RFC traceparent/tracestate)
- `parse_traceparent` returns a **remote parent context** — it must be passed to `span_start`, never to `span_end`

## Testing

```bash
mvl check src/          # type-check source files
```

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
