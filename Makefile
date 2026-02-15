.PHONY: test test-build test-down lint

test: ## Run all integration tests in Docker
	docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from test-runner
	docker compose -f docker-compose.test.yml down -v

test-build: ## Build test containers without running
	docker compose -f docker-compose.test.yml build

test-down: ## Tear down test containers and volumes
	docker compose -f docker-compose.test.yml down -v

lint: ## Run shellcheck on all scripts
	shellcheck backup-*.sh
