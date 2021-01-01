ORG_NAME = myorg
APP_NAME = sample-app

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

bootstrap: $(TOOLS_DIR)/bin/grype $(VENV_DIR)/bin/poetry $(VENV_DIR)/bin/pre-commit
	pre-commit install-hooks

$(TOOLS_DIR):
	mkdir -p $(TOOLS_DIR)

$(TOOLS_DIR)/bin/grype: $(TOOLS_DIR)
	curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b $(TOOLS_DIR)/bin

$(VENV_DIR)/bin/activate: $(TOOLS_DIR) pyproject.toml
	test -d $(VENV_DIR) || virtualenv -p python3 $(VENV_DIR)
	python3 -m pip install -U pip poetry pre-commit
	touch $(VENV_DIR)/bin/activate

$(VENV_DIR)/bin/poetry: $(VENV_DIR)/bin/activate
	$(VENV_DIR)/bin/python3 -m pip install poetry

$(VENV_DIR)/bin/pre-commit: $(VENV_DIR)/bin/activate
	$(VENV_DIR)/bin/python3 -m pip install pre-commit

.PHONY: test
test: bootstrap ## run all tests
	poetry run pytest -v

.PHONY: lint
lint: bootstrap ## lint the source code and configuration
	pre-commit run --all-files --hook-stage push

.PHONY: build-image
build-image: clean $(ID_FILE) ## build a docker image

$(ID_FILE):
	docker build --iidfile $(ID_FILE) .

.PHONY: test-image
test-image: bootstrap $(ID_FILE)  ## test a built docker image
	grype docker:$(shell cat $(ID_FILE)) --fail-on medium

publish: ## publish a docker image
	docker tag $(shell cat $(ID_FILE)) $(ORG_NAME)/$(APP_NAME):latest
	# this is where you would do a docker push

.PHONY: clean
clean:
	rm -f $(ID_FILE)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(BOLD)$(CYAN)%-25s$(RESET)%s\n", $$1, $$2}'
