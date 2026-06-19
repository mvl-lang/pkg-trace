# pkg/trace — distributed tracing with spans and trace context
.PHONY: help check test coverage prove assurance fmt lint version clean

.DEFAULT_GOAL := help

MVL ?= mvl
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: ## Type-check package source files
	$(MVL) check $(DIR)src/

test: ## Run unit tests
	$(MVL) test $(DIR)src/

coverage: ## Run tests with behavioral branch coverage report
	$(MVL) test $(DIR)src/ --coverage

prove: ## Per-call-site refinement proof breakdown (verbose)
	$(MVL) prove $(DIR)src/ --verbose

assurance: ## Full assurance: check + tests + assurance report
	$(MVL) check $(DIR)src/
	$(MVL) test $(DIR)src/
	$(MVL) assurance $(DIR)src/ --verbose

fmt: ## Format source files
	$(MVL) fmt $(DIR)src/

lint: ## Run linter
	$(MVL) lint $(DIR)src/

version: ## Show current package version from mvl.toml
	@grep '^version' mvl.toml | sed 's/version *= *"\(.*\)"/\1/'

clean: ## Remove build artifacts
	rm -rf $(TMPDIR)mvl_build_trace
