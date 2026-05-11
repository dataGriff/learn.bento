# 13 — Observability

> **Goal:** make a pipeline visible — Prometheus metrics, structured logs,
> distributed traces.

---

## What's new

| Concept | Where to look |
|---|---|
| `metrics.prometheus` — `/metrics` endpoint | `config.yaml` |
| `tracer.open_telemetry_collector` — OTLP traces | `config.yaml` |
| `logger` — JSON logs at INFO | `config.yaml` |
| Custom counters via the `metric` processor | `config.yaml` |
| Tagged metrics for cardinality | `config.yaml` |

---

## Run it

```bash
make ex13
```

Then in another terminal:

```bash
# Prometheus-format metrics
curl -s http://localhost:4197/metrics | grep -E 'bento_(input|output|processor)_' | head -20

# Stats snapshot as JSON
curl -s http://localhost:4197/stats | jq

# Custom counter we set in the mapping
curl -s http://localhost:4197/metrics | grep bento_orders_processed_total
```

---

## Custom metrics

Use the `metric` processor to emit your own counters/gauges/timings:

```yaml
- metric:
    type:  counter
    name:  orders_processed
    labels:
      tier: ${! this.tier }
    value: "1"
```

These appear in Prometheus as `bento_orders_processed_total{tier="..."}`.

---

## Tracing

The example exports OTLP spans to `http://localhost:4318` (the standard
OpenTelemetry collector port). If you have an OTLP-compatible backend
running (Jaeger, Tempo, Honeycomb, Datadog Agent, etc.) you'll see one
span per message, with attributes for the input topic and processor names.

Don't have one? Use a quick local Jaeger:

```bash
docker run -d --name jaeger -p 16686:16686 -p 4318:4318 \
  jaegertracing/all-in-one:latest
open http://localhost:16686
```

---

## Logger

```yaml
logger:
  level:           INFO
  format:          json
  add_timestamp:   true
  static_fields:
    service: bento-tutorial
    env:     local
```

JSON logs are easy to ship to anything (Loki, ELK, Datadog). Use the `log`
processor in your pipeline to emit structured per-message log lines:

```yaml
- log:
    level: INFO
    message: "processed order"
    fields_mapping: |
      root.order_id = this.order_id
      root.tier     = this.tier
```

---

## Things to try

1. Hit `/metrics` while messages flow and grep for `bento_input_received` and `bento_output_sent` — the difference is your in-flight count.
2. Add a label to your custom counter using a high-cardinality field — observe Prometheus complaining (and your wallet).
3. Set the log level to `DEBUG` and run example 08 — Bento will log every Kafka batch fetch and ack.

---

## Why this matters

A pipeline you can't measure is a pipeline you can't operate. The three
pillars (metrics + logs + traces) are first-class in Bento; turning them on
takes 5 lines of YAML.

Next → [14 — Testing pipelines](../14-testing-pipelines/)
