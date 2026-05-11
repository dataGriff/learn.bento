# 01 — What is Bento?

> **TL;DR** Bento is a single static binary that reads YAML and runs a streaming
> data pipeline. Inputs flow through processors and out to outputs.
> No code, no JVM, no cluster manager.

---

## The mental model

A Bento pipeline is a **directed graph of three stages**:

```
┌──────────┐    ┌─────────────────────────────┐    ┌──────────┐
│  INPUT   │ →  │  PIPELINE (processors[])    │ →  │  OUTPUT  │
└──────────┘    └─────────────────────────────┘    └──────────┘
   pulls            transforms / filters /              pushes
   bytes            enriches / routes                   bytes
```

Everything else — buffers, caches, rate limits, metrics, tracing, resources —
exists to support that core flow.

The smallest pipeline you can write:

```yaml
input:
  generate:
    mapping: 'root = "hello world"'
    interval: 1s

output:
  stdout: {}
```

Run it: `bento -c config.yaml`. Done. That's a pipeline.

---

## How it compares to neighbours

| Tool | Niche | When to pick it over Bento |
|---|---|---|
| **Kafka Connect** | Tight Kafka integration, JVM ecosystem | You're already deep in Confluent and need exactly-once Kafka↔DB |
| **Apache NiFi** | UI-driven, large enterprise flows | You need a visual canvas and provenance tracking |
| **Vector** | Logs / metrics observability pipelines | Pipeline is observability-only; you live in Rust-land |
| **Flink / Spark Streaming** | Stateful, complex event time, windows | You need real exactly-once stateful aggregations on huge state |
| **Bento** | "Glue-grade" stream processing, low ops | Default choice when you want a streaming Swiss-army knife |

Bento intentionally stays in the "stateless or lightly-stateful" lane. If your
windowed aggregation needs to survive a node crash with terabytes of state,
reach for Flink. For 90% of pipelines that move, transform, enrich, and route
events between systems — Bento is enough.

---

## Where it came from (and why naming is confusing)

- **2017–2024** — Ashley Jeffs wrote **Benthos**, an OSS streaming processor.
- **2024** — Redpanda acquired the project and rebranded it as
  **Redpanda Connect**. The OSS license terms shifted in a way some users
  disliked.
- **2024** — **WarpStream Labs** forked the last permissively-licensed
  Benthos and named it **Bento**, keeping it under the Apache-2.0 license.
- **2024** — Confluent acquired WarpStream. Bento's open governance continues.

This repo is about the **WarpStream Bento** fork. Configs are *largely*
compatible with Redpanda Connect, but resource and component names occasionally
diverge — when in doubt, consult <https://warpstreamlabs.github.io/bento/>.

---

## What makes it nice to use

- **Backpressure is built in** — slow outputs naturally slow inputs.
- **At-least-once by default** — every input/output ack contract is honoured.
- **Streams are observable** — prometheus, OTLP traces, JSON logs, all native.
- **Configs are testable** — `bento test` runs YAML-defined unit tests.
- **Configs are lintable** — `bento lint` catches typos and shape errors.
- **Configs are templatable** — env vars, secrets, Bloblang interpolation.

Continue → [02 — Installation](02-installation.md)
