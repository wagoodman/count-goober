ORG_NAME = myorg
APP_NAME = count-goober

# tools directory and paths
TOOLS_DIR = ./.tmp
VENV_DIR=$(TOOLS_DIR)/venv
VENV_ACTIVATE=. $(VENV_DIR)/bin/activate

# ensure we are preferring local tools over system tools
PATH := $(TOOLS_DIR)/bin:$(VENV_DIR)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash

# when building a docker image we don't want to tag it until it has been tested, this ID file contains the identity of the built image
ID_FILE = /tmp/$(ORG_NAME)-$(APP_NAME)-docker-build-id

all: lint test build-image test-image

bootstrap: $(TOOLS_DIR)/bin/grype $(VENV_DIR)/bin/poetry $(VENV_DIR)/bin/pre-commit $(TOOLS_DIR)/bin/hadolint
	pre-commit install-hooks

$(TOOLS_DIR):
	mkdir -p $(TOOLS_DIR)

$(TOOLS_DIR)/bin/hadolint: $(TOOLS_DIR)
	if [ "$(shell uname)" = "Darwin" ]; then \
		curl -o $(TOOLS_DIR)/bin/hadolint -sSfL https://github.com/hadolint/hadolint/releases/download/v1.19.0/hadolint-Darwin-x86_64; \
	else \
		curl -o $(TOOLS_DIR)/bin/hadolint -sSfL https://github.com/hadolint/hadolint/releases/download/v1.19.0/hadolint-Linux-x86_64; \
	fi
	chmod 755 $(TOOLS_DIR)/bin/hadolint

$(TOOLS_DIR)/bin/grype: $(TOOLS_DIR)
	curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b $(TOOLS_DIR)/bin

$(VENV_DIR)/bin/activate: $(TOOLS_DIR) pyproject.toml
	test -d $(VENV_DIR) || virtualenv -p python3 $(VENV_DIR)
	$(VENV_DIR)/bin/pip --version || $(VENV_DIR)/bin/python3 -m pip install -U pip

$(VENV_DIR)/bin/poetry: $(VENV_DIR)/bin/activate
	$(VENV_DIR)/bin/poetry --version || $(VENV_DIR)/bin/python3 -m pip install poetry

$(VENV_DIR)/bin/pre-commit: $(VENV_DIR)/bin/activate
	$(VENV_DIR)/bin/pre-commit --version || $(VENV_DIR)/bin/python3 -m pip install pre-commit

.PHONY: test
test: $(TOOLS_DIR) ## run all tests
	poetry run pytest -v

.PHONY: lint
lint: $(TOOLS_DIR) ## lint the source code and configuration
	pre-commit run  --all-files

.PHONY: build-image
build-image: clean $(ID_FILE) ## build a docker image

$(ID_FILE):
	docker build --iidfile $(ID_FILE) .

.PHONY: test-image
test-image: $(TOOLS_DIR) $(ID_FILE)  ## test a built docker image
	grype -v docker:$(shell cat $(ID_FILE)) --fail-on medium

publish: ## publish a docker image
	docker tag $(shell cat $(ID_FILE)) $(ORG_NAME)/$(APP_NAME):latest
	# this is where you would do a docker push

.PHONY: clean
clean:
	rm -f $(ID_FILE)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(BOLD)$(CYAN)%-25s$(RESET)%s\n", $$1, $$2}'
