ORG_NAME = myorg
APP_NAME = sample-app
ID_FILE = /tmp/$(ORG_NAME)-$(APP_NAME)-docker-build-id

all: lint test build-image test-image

.PHONY: bootstrap
bootstrap:
	# install grype
	grype || curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s --

	# install poetry
	poetry || curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

	# install pre-commit
	pre-commit || curl https://pre-commit.com/install-local.py | python -

.PHONY: test
test: ## run all tests
	poetry run pytest -v

.PHONY: lint
lint: ## lint the source code and configuration
	pre-commit run --all-files --hook-stage push

.PHONY: build-image
build-image: clean $(ID_FILE) ## build a docker image

$(ID_FILE):
	docker build --iidfile $(ID_FILE) .

.PHONY: test-image
test-image: $(ID_FILE)  ## test a built docker image
	grype docker:$(shell cat $(ID_FILE)) --fail-on medium

publish: ## publish a docker image
	docker tag $(shell cat $(ID_FILE)) $(ORG_NAME)/$(APP_NAME):latest
	# this is where you would do a docker push

.PHONY: clean
clean:
	rm $(ID_FILE)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(BOLD)$(CYAN)%-25s$(RESET)%s\n", $$1, $$2}'
