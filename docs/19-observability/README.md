---
title: "Observability"
series: bento
order: 19
description: "Make a pipeline visible — Prometheus metrics, structured JSON logs, and distributed OTLP traces."
canonical_url: https://hungovercoders.com/training/bento/19-observability
---

# 19 — Observability

> **Goal:** make a pipeline visible — Prometheus metrics, structured logs, distributed traces.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `metrics.prometheus` — `/metrics` endpoint | `config.yaml` |
| `tracer.open_telemetry_collector` — OTLP traces | `config.yaml` |
| `logger` — JSON logs at INFO | `config.yaml` |
| Custom counters via the `metric` processor | `config.yaml` |
| Tagged metrics for cardinality | `config.yaml` |

---

## The config

```yaml
http:
  address: 0.0.0.0:4197

input:
  generate:
    interval: 250ms
    mapping: |
      let tiers = ["gold","silver","bronze"]
      root.order_id = uuid_v4()
      root.amount   = random_int(min:1, max:300)
      root.tier     = $tiers.index(random_int(min:0, max:2))

pipeline:
  processors:

    - metric:
        type:  counter
        name:  orders_processed
        labels:
          tier: ${! this.tier }
        value: "1"

    - mapping: 'meta start_ns = timestamp_unix_nano()'
    - sleep:
        duration: 50ms
    - metric:
        type:  timing
        name:  fake_work_ns
        value: ${! timestamp_unix_nano() - meta("start_ns").number() }

    - log:
        level:   INFO
        message: "processed order"
        fields_mapping: |
          root.order_id = this.order_id
          root.tier     = this.tier
          root.amount   = this.amount

output:
  drop: {}

metrics:
  prometheus:
    use_histogram_timing: true

tracer:
  open_telemetry_collector:
    http:
      - url: http://localhost:4318
    grpc: []
    tags:
      service: bento-tutorial

logger:
  level:         INFO
  format:        json
  add_timestamp: true
  static_fields:
    service: bento-tutorial
    env:     local
```

**`metrics.prometheus`** exposes a `/metrics` endpoint at the `http.address` (port 4197 here). Bento automatically instruments every component — input received count, output sent count, processor errors, latency histograms — with no configuration required. `use_histogram_timing: true` emits timing metrics as histograms rather than summaries, which is what most Prometheus alerting rules expect.

**The `metric` processor** emits your own counters and timings from inside the pipeline. The `labels` field accepts Bloblang interpolation — `${! this.tier }` sets a label value per message. Keep label cardinality low: a label like `tier` (three values) is fine; a label like `order_id` (unbounded) will exhaust your Prometheus cardinality budget.

**Timing pattern:** stamp `meta start_ns` with `timestamp_unix_nano()` before a slow step, then emit a `timing` metric after by subtracting the start from the current nanosecond time. This works for any step you want to instrument — HTTP calls, database lookups, heavy Bloblang.

**`tracer.open_telemetry_collector`** exports OTLP spans to an OpenTelemetry collector or any compatible backend (Jaeger, Tempo, Honeycomb, Datadog). Each message becomes one root span. Bento populates attributes automatically from metadata and component names.

**`logger`** configures the process-level logger. `format: json` emits structured JSON logs — easy to ship to Loki, ELK, or Datadog. `static_fields` adds key-value pairs to every log line, so you can filter by `service` or `env` without instrumenting individual log calls.

**The `log` processor** emits a per-message log line at the specified level. `fields_mapping` is a Bloblang script that builds the structured fields for that line — here extracting `order_id`, `tier`, and `amount` from the message payload.

---

## Run it

```bash
make ex13
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Then in another terminal:

```bash
# Prometheus-format metrics
curl -s http://localhost:4197/metrics | grep -E 'bento_(input|output|processor)_' | head -20

# Stats snapshot as JSON
curl -s http://localhost:4197/stats | jq

# Custom counter labelled by tier
curl -s http://localhost:4197/metrics | grep bento_orders_processed_total
```

---

## Tracing

If you have a local Jaeger instance:

```bash
docker run -d --name jaeger -p 16686:16686 -p 4318:4318 \
  jaegertracing/all-in-one:latest
open http://localhost:16686
```

You'll see one trace per message with spans for each processor in the pipeline.

---

## Things to try

1. Hit `/metrics` while messages flow and compare `bento_input_received_total` with `bento_output_sent_total` — the difference is your in-flight count.
2. Add a label for a high-cardinality field like `order_id` — observe Prometheus memory grow rapidly (and understand why you shouldn't do this in production).
3. Set `level: DEBUG` and run a Kafka consumer example — Bento logs every batch fetch and offset commit.

---

## Why this matters

A pipeline you can't measure is a pipeline you can't operate. The three pillars — metrics, logs, traces — are first-class in Bento. Turning them on takes 5 lines of YAML; no SDK changes, no agent sidecars, no framework wiring.

