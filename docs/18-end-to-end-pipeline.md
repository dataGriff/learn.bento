---
title: "End-to-end Pipeline"
series: bento
order: 18
description: "Combine WarpStream consume, HTTP enrichment, windowed aggregation, fan-out, and DLQ routing into one production-grade pipeline."
canonical_url: https://hungovercoders.com/training/bento/18-end-to-end-pipeline
---

# 18 — End-to-end Pipeline

> **Goal:** combine everything — consume from WarpStream, enrich, validate, aggregate by window, fan out to multiple sinks (one of which is another WarpStream topic), with full DLQ handling.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md). WarpStream running — see [12 — WarpStream Setup](12-warpstream-setup.md).

> If you have the repo cloned: `make ex12`.
> Clone: `git clone https://github.com/hungovercoders/learn.bento.git`

---

## What this lesson covers

| Capability | From lesson |
|---|---|
| WarpStream consume | [14 — WarpStream Consume and Process](14-warpstream-consume-process.md) |
| HTTP + cache enrichment | [17 — Enrichment with HTTP and Cache](17-enrichment-http-cache.md) |
| `try` / `catch` / DLQ routing | [15 — Error Handling and DLQ](15-error-handling-dlq.md) |
| Tumbling windows + aggregation | [16 — Windowing and Aggregation](16-windowing-aggregation.md) |
| Fan-out to multiple sinks | [11 — Fan-out Broker](11-fan-out-broker.md) |
| Bloblang transforms throughout | [09 — Bloblang Transform](09-bloblang-transform.md) |

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

## The config

```yaml
http:
  address: 0.0.0.0:4196

input:
  kafka_franz:
    seed_brokers:      [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topics:            [ "${IN_TOPIC:orders}" ]
    consumer_group:    "${GROUP:bento-orders-end-to-end}"
    start_from_oldest: true

cache_resources:
  - label: zip_cache
    memory:
      default_ttl: 1h

rate_limit_resources:
  - label: zip_api
    local: { count: 5, interval: 1s }

pipeline:
  processors:

    - try:
        - mapping: |
            if this.order_id   == null { throw("missing order_id") }
            if this.customer_id == null { throw("missing customer_id") }
            if this.qty == null || this.qty <= 0 { throw("bad qty") }
            if this.price == null || this.price < 0 { throw("bad price") }
            root = this
            root.total = this.qty * this.price
            root.zip   = this.zip.or("90210")

    - try:
        - branch:
            request_map: 'root = this.zip'
            processors:
              - cache: { resource: zip_cache, operator: get, key: '${! content() }' }
              - catch:
                  - http:
                      url: https://api.zippopotam.us/us/${! content() }
                      verb: GET
                      rate_limit: zip_api
                  - cache: { resource: zip_cache, operator: set, key: '${! content() }', value: '${! content() }' }
              - mapping: |
                  let body = content().parse_json()
                  root.city    = $body.places.index(0).get("place name")
                  root.state   = $body.places.index(0).get("state")
                  root.country = $body.country
            result_map: 'root.location = this'

    - catch:
        - mapping: |
            root.original  = content().string()
            root.error     = error()
            root.failed_at = now()
            meta dlq       = "true"

buffer:
  system_window:
    timestamp_mapping: 'root = now()'
    size:  10s
    slack: 1s

output:
  switch:
    cases:

      - check: errored() || meta("dlq") == "true"
        output:
          broker:
            pattern: fan_out
            outputs:
              - kafka_franz:
                  seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
                  topic:        "${DLQ_TOPIC:orders.dlq}"
              - file:
                  path:  ./examples/12-end-to-end-pipeline/out/dlq.jsonl
                  codec: lines

      - processors:
          - group_by_value:
              value: ${! this.customer_id }
          - archive:
              format: json_array
          - mapping: |
              root.window_end   = now()
              root.customer_id  = this.index(0).customer_id
              root.order_count  = this.length()
              root.total_amount = this.map_each(o -> o.total).sum()
              root.cities       = this.map_each(o -> o.location.city).unique()
              meta kafka_key    = root.customer_id
        output:
          broker:
            pattern: fan_out
            outputs:
              - kafka_franz:
                  seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
                  topic:        "${OUT_TOPIC:orders.rollup}"
                  key:          ${! meta("kafka_key") }
              - file:
                  path:  ./examples/12-end-to-end-pipeline/out/rollups.jsonl
                  codec: lines

metrics:
  prometheus: {}

logger:
  level:  INFO
  format: json
```

**Reading the config top-to-bottom:**

1. `http.address: 0.0.0.0:4196` — admin/metrics endpoint on a different port to avoid clashing with lesson 08.
2. `input.kafka_franz` — standard consumer group setup from lesson 14.
3. `cache_resources` + `rate_limit_resources` — same setup as lesson 17.
4. First `try` block — validation. Any missing or invalid field causes the message to skip to `catch`.
5. Second `try` block — enrichment branch. If the HTTP lookup fails, the message also falls to `catch`.
6. `catch` — annotates errored messages and sets the `dlq` metadata flag.
7. `buffer.system_window` — all messages (including errored ones) accumulate in 10-second windows.
8. `output.switch` — the first case routes DLQ messages to both the DLQ topic and a local file. The second case (no `check` — the default) runs windowed aggregation and fans out to the rollup topic and a local file.

The new idea here is **layering**: an enrichment branch inside a `try`, inside a larger pipeline that also has a window buffer. Each block is individually familiar; the skill is composing them without losing track of error state.

---

## Prerequisites

```bash
make warpstream-up
make ws-topic NAME=orders        PARTITIONS=3
make ws-topic NAME=orders.dlq    PARTITIONS=1
make ws-topic NAME=orders.rollup PARTITIONS=3
```

Then start the producer in another terminal:

```bash
make ex07
```

---

## Run it

```bash
make ex12
```

Watch the output topic:

```bash
make ws-consume TOPIC=orders.rollup
```

And the local files:

```bash
tail -f examples/12-end-to-end-pipeline/out/rollups.jsonl
tail -f examples/12-end-to-end-pipeline/out/dlq.jsonl
```

---

## Things to try

1. Replace the public zip API with a mocked `http_server` that returns slow or error responses — observe `try`/`catch` in action and messages landing in the DLQ.
2. Add a metrics + tracer block (see lesson 19) and scrape Prometheus.
3. Add `bento test` cases (see lesson 20) for the validation step.

Continue → [19 — Observability](19-observability.md)
