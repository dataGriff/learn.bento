# learn.bento — convenience targets.
#
# Most targets prefer the locally-installed `bento` binary, falling back to a
# Dockerised bento via docker-compose if it's not on $PATH. Override with:
#   make ex01 BENTO="docker compose run --rm bento"

BENTO    ?= $(shell command -v bento 2>/dev/null || echo "docker compose run --rm bento")
COMPOSE  ?= docker compose

.DEFAULT_GOAL := help

# ──────────────────────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────────────────────

help: ## Show this help.
	@awk 'BEGIN{FS=":.*##"; printf "Targets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ──────────────────────────────────────────────────────────────────────────────
# WarpStream lifecycle
# ──────────────────────────────────────────────────────────────────────────────

warpstream-up: ## Start WarpStream + kafka-tools containers.
	$(COMPOSE) up -d warpstream kafka-tools
	@echo "WarpStream is starting on localhost:9092 (give it ~10s)."

warpstream-down: ## Stop the local WarpStream stack (preserves volumes).
	$(COMPOSE) down

ws-topic: ## Create a topic.   Usage: make ws-topic NAME=orders PARTITIONS=3
	@: $${NAME?Set NAME=<topic>}
	$(COMPOSE) exec -T kafka-tools rpk topic create $(NAME) \
		--partitions $${PARTITIONS:-1} --brokers warpstream:9092

ws-topics: ## List topics on the local WarpStream.
	$(COMPOSE) exec -T kafka-tools rpk topic list --brokers warpstream:9092

ws-consume: ## Tail a topic.   Usage: make ws-consume TOPIC=orders
	@: $${TOPIC?Set TOPIC=<topic>}
	$(COMPOSE) exec -T kafka-tools rpk topic consume $(TOPIC) --brokers warpstream:9092

# ──────────────────────────────────────────────────────────────────────────────
# Tutorial examples — `make exNN`
# ──────────────────────────────────────────────────────────────────────────────

ex01: ## 03 — hello world
	(cd docs/03-hello-world && $(BENTO) -c config.yaml)

ex02: ## 07 — file to file (CSV → JSON)
	(cd docs/07-file-to-file && $(BENTO) -c config.yaml)

ex03: ## 08 — HTTP server input
	(cd docs/08-http-server-input && $(BENTO) -c config.yaml)

ex04: ## 09 — Bloblang transform
	(cd docs/09-bloblang-transform && $(BENTO) -c config.yaml)

ex05: ## 10 — filter & route
	(cd docs/10-filter-and-route && $(BENTO) -c config.yaml)

ex06: ## 11 — fan-out broker
	(cd docs/11-fan-out-broker && $(BENTO) -c config.yaml)

ex07: ## 13 — WarpStream produce
	(cd docs/13-warpstream-produce && $(BENTO) -c config.yaml)

ex08: ## 14 — WarpStream consume + process
	(cd docs/14-warpstream-consume-process && $(BENTO) -c config.yaml)

ex09: ## 15 — error handling & DLQ
	(cd docs/15-error-handling-dlq && $(BENTO) -c config.yaml)

ex10: ## 16 — windowing & aggregation
	(cd docs/16-windowing-aggregation && $(BENTO) -c config.yaml)

ex11: ## 17 — enrichment (HTTP + cache)
	(cd docs/17-enrichment-http-cache && $(BENTO) -c config.yaml)

ex12: ## 18 — end-to-end pipeline
	(cd docs/18-end-to-end-pipeline && $(BENTO) -c config.yaml)

ex13: ## 19 — observability
	(cd docs/19-observability && $(BENTO) -c config.yaml)

ex14: ## 20 — pipeline tests (`bento test`)
	(cd docs/20-testing-pipelines && $(BENTO) test config.yaml)

# ──────────────────────────────────────────────────────────────────────────────
# Quality / housekeeping
# ──────────────────────────────────────────────────────────────────────────────

lint: ## Lint all lesson configs.
	@for f in docs/*/config.yaml; do \
		echo "==> $$f"; \
		$(BENTO) lint "$$f" || exit 1; \
	done

test: ## Run all bento tests in the repo.
	$(BENTO) test ./docs/...

clean: ## Remove generated lesson outputs.
	rm -rf docs/*/out

clean-all: clean warpstream-down ## Outputs + containers.

.PHONY: help warpstream-up warpstream-down ws-topic ws-topics ws-consume \
        ex01 ex02 ex03 ex04 ex05 ex06 ex07 ex08 ex09 ex10 ex11 ex12 ex13 ex14 \
        lint test clean clean-all
