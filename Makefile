# https://hub.docker.com/r/helmunittest/helm-unittest/tags/
HELM_3_UNITTEST_IMAGE ?= docker.io/helmunittest/helm-unittest:3.21.0-1.0.3
HELM_4_UNITTEST_IMAGE ?= docker.io/helmunittest/helm-unittest:4.2.4-1.2.1


HELM_DOCS_IMAGE ?= docker.io/jnorwood/helm-docs:latest

PWD=$(shell pwd)
MYNAME=$(shell id -n -u)
MYUID=$(shell id -u)
MYGID=$(shell id -g)
PODMAN_ARGS := --security-opt label=disable --net=host --rm --passwd-entry "$(MYNAME):x:$(MYUID):$(MYGID)::/apps:/bin/bash" --user $(MYUID):$(MYGID) --userns keep-id:uid=$(MYUID),gid=$(MYGID)
##@ Common Tasks

.PHONY: help
help: ## This help message
	@echo "Pattern: $(NAME)"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^(\s|[a-zA-Z_0-9-])+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: helm-lint
helm-lint: ## Runs helm lint against the chart
	helm lint .

.PHONY: helm-unittest unittest
helm-unittest: ## Runs the helm unit tests
	podman run $(PODMAN_ARGS) -v $(PWD):/apps:rw $(HELM_3_UNITTEST_IMAGE) .
	podman run $(PODMAN_ARGS) -v $(PWD):/apps:rw $(HELM_4_UNITTEST_IMAGE) .

unittest: helm-unittest ## Alias for helm-unittest

.PHONY: test
test: helm-lint helm-unittest ## Runs helm lint and unit tests

.PHONY: super-linter
super-linter: ## Runs super linter locally
	rm -rf .mypy_cache
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true	\
					-e VALIDATE_BIOME_FORMAT=false \
					-e VALIDATE_BIOME_LINT=false \
					-e VALIDATE_PYTHON_RUFF=false \
					-e VALIDATE_PYTHON_RUFF_FORMAT=false \
					-e FILTER_REGEX_EXCLUDE='.*templates/.*' \
					-e VALIDATE_GITHUB_ACTIONS_ZIZMOR=false \
					-e VALIDATE_TRIVY=false \
					-e FIX_YAML_PRETTIER=true \
					-v $(PWD):/tmp/lint:rw,z \
					-w /tmp/lint \
					ghcr.io/super-linter/super-linter:v8.1.0