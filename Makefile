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

ex01: ## 01 — hello world
	$(BENTO) -c examples/01-hello-world/config.yaml

ex02: ## 02 — file to file (CSV → JSON)
	$(BENTO) -c examples/02-file-to-file/config.yaml

ex03: ## 03 — HTTP server input
	$(BENTO) -c examples/03-http-server-input/config.yaml

ex04: ## 04 — Bloblang transform
	$(BENTO) -c examples/04-bloblang-transform/config.yaml

ex05: ## 05 — filter & route
	$(BENTO) -c examples/05-filter-and-route/config.yaml

ex06: ## 06 — fan-out broker
	$(BENTO) -c examples/06-fan-out-broker/config.yaml

ex07: ## 07 — WarpStream produce
	$(BENTO) -c examples/07-warpstream-produce/config.yaml

ex08: ## 08 — WarpStream consume + process
	$(BENTO) -c examples/08-warpstream-consume-process/config.yaml

ex09: ## 09 — error handling & DLQ
	$(BENTO) -c examples/09-error-handling-dlq/config.yaml

ex10: ## 10 — windowing & aggregation
	$(BENTO) -c examples/10-windowing-aggregation/config.yaml

ex11: ## 11 — enrichment (HTTP + cache)
	$(BENTO) -c examples/11-enrichment-http-cache/config.yaml

ex12: ## 12 — end-to-end pipeline
	$(BENTO) -c examples/12-end-to-end-pipeline/config.yaml

ex13: ## 13 — observability
	$(BENTO) -c examples/13-observability/config.yaml

ex14: ## 14 — pipeline tests (`bento test`)
	$(BENTO) test examples/14-testing-pipelines/config.yaml

# ──────────────────────────────────────────────────────────────────────────────
# Quality / housekeeping
# ──────────────────────────────────────────────────────────────────────────────

lint: ## Lint all example configs.
	@for f in examples/*/config.yaml; do \
		echo "==> $$f"; \
		$(BENTO) lint "$$f" || exit 1; \
	done

test: ## Run all bento tests in the repo.
	$(BENTO) test ./examples/...

clean: ## Remove generated example outputs.
	rm -rf examples/*/out

clean-all: clean warpstream-down ## Outputs + containers.

.PHONY: help warpstream-up warpstream-down ws-topic ws-topics ws-consume \
        ex01 ex02 ex03 ex04 ex05 ex06 ex07 ex08 ex09 ex10 ex11 ex12 ex13 ex14 \
        lint test clean clean-all
