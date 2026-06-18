# pkg/trace — distributed tracing with spans and trace context
.PHONY: help guard-mvl check test coverage prove assurance version clean

.DEFAULT_GOAL := help

MVL := $(shell test -x ../../target/debug/mvl && echo ../../target/debug/mvl || echo mvl)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

guard-mvl: ## Validate MVL binary is present
	@$(MVL) --version > /dev/null 2>&1 || { \
		echo ""; \
		echo "  ERROR: MVL compiler not found at: $(MVL)"; \
		echo "  Run 'make build' from the repo root, or install mvl to PATH."; \
		echo ""; \
		exit 1; \
	}

check: guard-mvl ## Type-check package source files
	$(MVL) check $(DIR)src/

test: guard-mvl ## Run unit tests
	$(MVL) test $(DIR)src/

coverage: guard-mvl ## Run tests with behavioral branch coverage report
	$(MVL) test $(DIR)src/ --coverage

prove: guard-mvl ## Per-call-site refinement proof breakdown (verbose)
	$(MVL) prove $(DIR)src/ --verbose

assurance: guard-mvl ## Full assurance: check + tests + assurance report
	$(MVL) check $(DIR)src/
	$(MVL) test $(DIR)src/
	$(MVL) assurance $(DIR)src/ --verbose

version: ## Show current package version from mvl.toml
	@grep '^version' mvl.toml | sed 's/version *= *"\(.*\)"/\1/'

clean: ## Remove build artifacts
	rm -rf $(TMPDIR)mvl_build_trace
