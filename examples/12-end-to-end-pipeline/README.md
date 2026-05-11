# 12 — End-to-end pipeline

> **Goal:** combine everything — consume from WarpStream, enrich, validate,
> aggregate by window, fan out to multiple sinks (one of which is another
> WarpStream topic), with full DLQ handling.

This is the example to point at when someone asks "what does a real Bento
pipeline look like?".

---

## What's combined

| Capability | From example |
|---|---|
| WarpStream consume | 08 |
| HTTP + cache enrichment | 11 |
| try / catch / DLQ routing | 09 |
| Tumbling windows + aggregation | 10 |
| Fan-out to multiple sinks (WarpStream + file) | 06 |
| Bloblang transforms throughout | 04 |

---

## Topology

```
                    ┌─────────────┐
WarpStream:orders ─▶│  validate   │── err ──▶ WarpStream:orders.dlq
                    │  enrich     │              + file dlq.jsonl
                    │  (cache)    │
                    └─────┬───────┘
                          │ ok
                          ▼
                    ┌─────────────┐
                    │ window 10s  │
                    │ group_by    │
                    │ aggregate   │
                    └─────┬───────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
   WarpStream:orders.rollup   file: rollups.jsonl
```

---

## Prerequisites

```bash
make warpstream-up
make ws-topic NAME=orders        PARTITIONS=3
make ws-topic NAME=orders.dlq    PARTITIONS=1
make ws-topic NAME=orders.rollup PARTITIONS=3
```

…and have something producing to `orders` (e.g. `make ex07`).

---

## Run it

```bash
make ex12
```

Watch the output topic:

```bash
make ws-consume TOPIC=orders.rollup
```

…and the local files for sanity:

```bash
tail -f examples/12-end-to-end-pipeline/out/rollups.jsonl
tail -f examples/12-end-to-end-pipeline/out/dlq.jsonl
```

---

## What to study in `config.yaml`

Read it top-to-bottom — every block you see has been explained in an earlier
example. The only new idea is **layering**: an enrichment branch wrapped in
a `try`, followed by a windowing buffer, followed by a fan-out output that
itself contains a switch.

This kind of "layered" pipeline is normal in production. Don't be intimidated
by the size — Bento configs grow vertically, not in nesting depth.

---

## Things to try

1. Replace the public zip API with a mocked `http_server` that returns a
   slow / error-throwing response — observe `try`/`catch` in action, and
   the corresponding messages landing in the DLQ topic.
2. Add a metrics + tracer block (see example 13) and scrape Prometheus.
3. Add `bento test` cases (see example 14) for the validation step.

Next → [13 — Observability](../13-observability/)
